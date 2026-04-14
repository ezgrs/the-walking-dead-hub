import asyncio
import sys
import types
import typing
import threading
import queue

import bs4
import playwright.async_api

from twd_hub.domain.interfaces.html_loader_service import HtmlLoader


def run_worker_sync(
    request_queue: queue.Queue[str | None],
    response_queue: queue.Queue[tuple[str, str] | Exception],
) -> None:
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    try:
        loop.run_until_complete(
            run_worker_async(
                request_queue=request_queue,
                response_queue=response_queue,
            )
        )
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
                request_data = await asyncio.to_thread(request_queue.get)
                if request_data is None:
                    break

                url, wait_until_selector = request_data

                page: playwright.async_api.Page
                async with await browser.new_page(
                    # Makes headless browser look like a real browser
                    # Without this, `page.wait_for_selector` timeouts
                    user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
                    viewport={"width": 1280, "height": 800},
                    locale="en-US",
                ) as page:
                    await page.goto(url)
                    if wait_until_selector:
                        await page.wait_for_selector(wait_until_selector)
                    html = await page.content()

                await asyncio.to_thread(response_queue.put, (url, html))


class PlaywrightHtmlLoader(HtmlLoader):
    request_queue: queue.Queue[tuple[str, str | None] | None]
    response_queue: queue.Queue[tuple[str, str] | Exception]
    worker: threading.Thread

    @typing.override
    async def __aenter__(self) -> "HtmlLoader":
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
    async def load(
        self, url: str, *, wait_until_selector: str | None = None
    ) -> str:
        self.request_queue.put((url, wait_until_selector))

        def wait_result() -> str:
            while True:
                response_data = self.response_queue.get()
                if isinstance(response_data, Exception):
                    raise response_data

                current_url, content = response_data
                if current_url == url:
                    return content

        return await asyncio.to_thread(wait_result)

    @typing.override
    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: types.TracebackType | None,
    ) -> bool | None:
        self.request_queue.put(None)
        await asyncio.to_thread(self.worker.join)
