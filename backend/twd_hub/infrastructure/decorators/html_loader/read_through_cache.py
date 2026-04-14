import types
import typing

from twd_hub.domain.interfaces.cache_store_service import CacheStore
from twd_hub.domain.interfaces.html_loader_service import HtmlLoader


class ReadThroughCacheHtmlLoader(HtmlLoader):
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
        content = await self.cache.get(url)
        if content is not None:
            return content.decode(encoding="utf-8")

        return await self.loader.load(
            url, wait_until_selector=wait_until_selector
        )

    @typing.override
    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: types.TracebackType | None,
    ) -> bool | None:
        return await self.loader.__aexit__(exc_type, exc_value, traceback)
