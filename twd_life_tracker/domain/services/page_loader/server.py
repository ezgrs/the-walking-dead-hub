import asyncio
import contextlib
import types
import typing

import bs4
import playwright.sync_api

from . import PageLoader as BasePageLoader

import multiprocessing
import multiprocessing.queues

def run_playwright_worker(
    request_queue: multiprocessing.queues.Queue[str | None],
    response_queue: multiprocessing.queues.Queue[tuple[str, str]],
) -> None:
    with playwright.sync_api.sync_playwright() as p:
        with p.chromium.launch(
            executable_path="C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
            headless=False,
        ) as browser:
            while True:
                href = request_queue.get()
                if href is None:
                    break

                with browser.new_page() as page:
                    page.goto(f"https://walkingdead.fandom.com{href}")
                    page.wait_for_selector("#Trivia")
                    html = page.content()

                response_queue.put((href, html))


class PageLoader(BasePageLoader):
    request_queue: multiprocessing.queues.Queue[str | None]
    response_queue: multiprocessing.queues.Queue[tuple[str, str]]
    worker: multiprocessing.Process

    @typing.override
    async def __aenter__(self) -> "PageLoader":
        self.request_queue = multiprocessing.Queue()
        self.response_queue = multiprocessing.Queue()

        self.worker = multiprocessing.Process(
            target=run_playwright_worker,
            args=(self.request_queue, self.response_queue),
        )
        await asyncio.to_thread(self.worker.start)
        return await super().__aenter__()

    @typing.override
    async def load(self, href: str) -> bs4.BeautifulSoup:
        self.request_queue.put(href)

        def wait_result() -> str:
            while True:
                current_href, content = self.response_queue.get()
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
