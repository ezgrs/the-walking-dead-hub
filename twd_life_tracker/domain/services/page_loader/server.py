import contextlib
import types
import typing

import bs4
import playwright.async_api

from . import PageLoader as BasePageLoader


class PageLoader(BasePageLoader):
    exit_stack: contextlib.AsyncExitStack
    browser: playwright.async_api.Browser

    def __init__(self) -> None:
        self.exit_stack = contextlib.AsyncExitStack()

    @typing.override
    async def __aenter__(self) -> "PageLoader":
        p = await self.exit_stack.enter_async_context(
            playwright.async_api.async_playwright()
        )
        self.browser = await self.exit_stack.enter_async_context(
            await p.chromium.launch(
                executable_path="C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
                headless=False,
            )
        )
        return await super().__aenter__()

    @typing.override
    async def load(self, href: str) -> bs4.BeautifulSoup:
        async with await self.browser.new_page() as page:
            await page.goto(f"https://walkingdead.fandom.com{href}")
            await page.wait_for_selector("#Trivia")
            return bs4.BeautifulSoup(
                await page.content(), features="html.parser"
            )

    @typing.override
    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: types.TracebackType | None,
    ) -> bool | None:
        return await self.exit_stack.__aexit__(exc_type, exc_value, traceback)
