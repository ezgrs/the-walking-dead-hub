import json
import typing
import urllib.parse
from twd_hub.application.services.episode_page_scraper import (
    EpisodePageScraper,
)
from twd_hub.domain.interfaces.cache_store_service import CacheStore
from twd_hub.domain.models.episode_page import EpisodePage


class ReadThroughCacheEpisodePageScraper(EpisodePageScraper):
    scraper: EpisodePageScraper
    cache: CacheStore

    def __init__(
        self, scraper: EpisodePageScraper, *, cache: CacheStore
    ) -> None:
        self.scraper = scraper
        self.cache = cache

    @typing.override
    async def scrape(
        self, url: str, *, wait_until_selector: str | None = None
    ) -> EpisodePage:
        href = urllib.parse.urlparse(url)
        content = await self.cache.get(f"episodepage:{href}")
        if content is not None:
            return EpisodePage(**json.loads(content.decode(encoding="utf-8")))

        return await self.scraper.scrape(
            url, wait_until_selector=wait_until_selector
        )
