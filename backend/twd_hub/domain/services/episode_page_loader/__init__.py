import abc
import redis.asyncio


from twd_hub.domain.models import EpisodePage
from twd_hub.domain.services.page_loader import PageLoader
from twd_hub.domain.services.tag_parser import TagParser


class EpisodeLoader(abc.ABC):
    @classmethod
    def from_server(
        cls,
        *,
        page_loader: PageLoader,
        tag_parser: TagParser[EpisodePage],
    ) -> "EpisodeLoader":
        from .server import EpisodeLoader

        return EpisodeLoader(
            page_loader=page_loader,
            tag_parser=tag_parser,
        )

    @abc.abstractmethod
    async def load(self, href: str) -> EpisodePage: ...

    def with_read_through_cache(
        self,
        r: redis.asyncio.Redis,
    ) -> "EpisodeLoader":
        from .read_through_cache import EpisodeLoader

        return EpisodeLoader(loader=self, r=r)

    def with_write_through_cache(
        self,
        r: redis.asyncio.Redis,
    ) -> "EpisodeLoader":
        from .write_through_cache import EpisodeLoader

        return EpisodeLoader(loader=self, r=r)
