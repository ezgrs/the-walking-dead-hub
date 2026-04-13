import hashlib
import types
import typing

import aiopath
import bs4

from . import PageLoader as BasePageLoader


class PageLoader(BasePageLoader):
    dpath: aiopath.AsyncPath
    loader: BasePageLoader

    def __init__(
        self,
        *,
        dpath: aiopath.Path,
        loader: BasePageLoader,
    ) -> None:
        self.dpath = dpath
        self.loader = loader

    @typing.override
    async def __aenter__(self) -> "PageLoader":
        return await self.loader.__aenter__()

    @typing.override
    async def load(self, href: str) -> bs4.BeautifulSoup:
        href_slug = href.strip("/").replace("/", "_")
        href_hash_text = hashlib.md5(href_slug.encode()).hexdigest()
        fpath: aiopath.AsyncPath = (
            self.dpath / f"{href_slug}_{href_hash_text[:6]}.cache"
        )

        soup = await self.loader.load(href)
        await self.dpath.mkdir(exist_ok=True, parents=True)
        async with fpath.open("w+", encoding="utf-8") as f:
            await f.write(str(soup))  # pyright: ignore[reportArgumentType]

        return soup

    @typing.override
    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: types.TracebackType | None,
    ) -> bool | None:
        return await self.loader.__aexit__(exc_type, exc_value, traceback)
