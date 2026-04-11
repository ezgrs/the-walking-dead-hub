import abc
import typing

import aiopath
import bs4


class PageLoader(typing.AsyncContextManager, abc.ABC):
    @classmethod
    def from_server(cls) -> "PageLoader":
        from .server import PageLoader

        return PageLoader()

    @abc.abstractmethod
    async def load(self, href: str) -> bs4.BeautifulSoup: ...

    def with_read_through_cache(
        self, cache_dir_path: aiopath.Path
    ) -> "PageLoader":
        from .read_through_cache import PageLoader

        return PageLoader(
            loader=self,
            dpath=cache_dir_path,
        )

    def with_write_through_cache(
        self, cache_dir_path: aiopath.Path
    ) -> "PageLoader":
        from .write_through_cache import PageLoader

        return PageLoader(
            loader=self,
            dpath=cache_dir_path,
        )
