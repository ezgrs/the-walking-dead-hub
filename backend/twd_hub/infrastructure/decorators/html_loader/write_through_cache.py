import types
import typing

from twd_hub.domain.interfaces.cache_store_service import CacheStore
from twd_hub.domain.interfaces.html_loader_service import HtmlLoader


class WriteThroughCacheHtmlLoader(HtmlLoader):
    loader: HtmlLoader
    cache: CacheStore

    def __init__(self, loader: HtmlLoader, cache: CacheStore):
        self.loader = loader
        self.cache = cache

    @typing.override
    async def __aenter__(self) -> "HtmlLoader":
        return await self.loader.__aenter__()

    @typing.override
    async def load(
        self, url: str, *, wait_until_selector: str | None = None
    ) -> str:
        content = await self.loader.load(
            url, wait_until_selector=wait_until_selector
        )
        await self.cache.set(url, str(content).encode(encoding="utf-8"))
        return content

    @typing.override
    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: types.TracebackType | None,
    ) -> bool | None:
        return await self.loader.__aexit__(exc_type, exc_value, traceback)
