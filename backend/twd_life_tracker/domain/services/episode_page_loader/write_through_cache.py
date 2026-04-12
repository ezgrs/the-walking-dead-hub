import typing

import redis.asyncio

from twd_life_tracker.domain.models import EpisodePage
from twd_life_tracker.domain.services.episode_page_loader import EpisodeLoader as BaseEpisodeLoader



class EpisodeLoader(BaseEpisodeLoader):
    r: redis.asyncio.Redis
    loader: BaseEpisodeLoader

    def __init__(
        self,
        *,
        r: redis.asyncio.Redis,
        loader: BaseEpisodeLoader,
    ) -> None:
        self.r = r
        self.loader = loader

    @typing.override
    async def load(self, href: str) -> EpisodePage:
        cache_key = f"episodepage:{href}"
        episode_page = await self.loader.load(href)
        await self.r.set(
            cache_key,
            episode_page.model_dump_json(),
            ex=86400,
        )
        return episode_page
