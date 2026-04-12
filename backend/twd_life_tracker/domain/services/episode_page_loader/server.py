import typing

import redis.asyncio

from twd_life_tracker.domain.models import EpisodePage
from twd_life_tracker.domain.services.episode_page_loader import EpisodeLoader as BaseEpisodeLoader
from twd_life_tracker.domain.services.page_loader import PageLoader
from twd_life_tracker.domain.services.tag_parser import TagParser



class EpisodeLoader(BaseEpisodeLoader):
    page_loader: PageLoader
    tag_parser: TagParser[EpisodePage]

    def __init__(
        self,
        *,
        page_loader: PageLoader,
        tag_parser: TagParser[EpisodePage],
    ) -> None:
        self.page_loader = page_loader
        self.tag_parser = tag_parser

    @typing.override
    async def load(self, href: str) -> EpisodePage:
        soup = await self.page_loader.load(href)
        return await self.tag_parser.parse(soup)
