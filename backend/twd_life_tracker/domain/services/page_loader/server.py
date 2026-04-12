import asyncio
import sys
import types
import typing
import threading
import queue

import bs4
import playwright.async_api

from . import PageLoader as BasePageLoader


def run_worker_sync(
    request_queue: queue.Queue[str | None],
    response_queue: queue.Queue[tuple[str, str] | Exception],
) -> None:
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    try:
        loop.run_until_complete(run_worker_async(
            request_queue=request_queue,
            response_queue=response_queue,
        ))
    except Exception as e:
        response_queue.put(e)
        raise
    finally:
        loop.close()


async def run_worker_async(
    *,
    request_queue: queue.Queue[str | None],
    response_queue: queue.Queue[tuple[str, str] | Exception],
) -> None:
    async with playwright.async_api.async_playwright() as p:
        async with await p.chromium.launch() as browser:
            while True:
                href = await asyncio.to_thread(request_queue.get)
                if href is None:
                    break

                async with await browser.new_page(
                    # Makes headless browser look like a real browser
                    # Without this, `page.wait_for_selector` timeouts
                    user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
                    viewport={"width": 1280, "height": 800},
                    locale="en-US",
                ) as page:
                    await page.goto(f"https://walkingdead.fandom.com{href}")
                    await page.wait_for_selector("#Trivia")
                    html = await page.content()

                await asyncio.to_thread(response_queue.put, (href, html))


class PageLoader(BasePageLoader):
    request_queue: queue.Queue[str | None]
    response_queue: queue.Queue[tuple[str, str] | Exception]
    worker: threading.Thread

    @typing.override
    async def __aenter__(self) -> "PageLoader":
        self.request_queue = queue.Queue()
        self.response_queue = queue.Queue()

        # The asyncio.WindowsSelectorEventLoopPolicy is necessary for the main
        # thread because psycopg requires it, otherwise it throws a 
        # psycopg.InterfaceError (for instance, see https://stackoverflow.com/q/71219607).
        #
        # However, Playwright uses asyncio.create_subprocess_exec under the 
        # hood, which throws NotImplementedError with that loop policy.
        # Therefore, a new thread with asyncio.WindowsProactorEventLoopPolicy
        # is required for Playwright to work properly.
        #
        # Communication is made using `queue.Queue`s.
        self.worker = threading.Thread(
            target=run_worker_sync,
            args=(self.request_queue, self.response_queue),
        )
        self.worker.start()
        return await super().__aenter__()

    @typing.override
    async def load(self, href: str) -> bs4.BeautifulSoup:
        self.request_queue.put(href)

        def wait_result() -> str:
            while True:
                response_data = self.response_queue.get()
                if isinstance(response_data, Exception):
                    raise response_data

                current_href, content = response_data 
                if current_href == href:
                    return content

        content = await asyncio.to_thread(wait_result)
        return bs4.BeautifulSoup(content, features="html.parser")

    @typing.override
    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: types.TracebackType | None,
    ) -> bool | None:
        self.request_queue.put(None)
        await asyncio.to_thread(self.worker.join)
