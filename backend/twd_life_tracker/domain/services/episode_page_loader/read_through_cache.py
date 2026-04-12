import json
import typing

import redis.asyncio

from twd_life_tracker.domain.models import EpisodePage
from twd_life_tracker.domain.services.episode_page_loader import (
    EpisodeLoader as BaseEpisodeLoader,
)


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
        if await self.r.exists(cache_key):
            data = await self.r.get(cache_key)
            return EpisodePage(**json.loads(data))

        return await self.loader.load(href)
