import json
import typing
import urllib.parse
from twd_hub.application.services.scraper import (
    Scraper,
)
from twd_hub.domain.interfaces.cache_store_service import CacheStore
from twd_hub.domain.models.episode_page import EpisodePage


class ReadThroughCacheScraper(Scraper):
    scraper: Scraper
    cache: CacheStore

    def __init__(self, scraper: Scraper, *, cache: CacheStore) -> None:
        self.scraper = scraper
        self.cache = cache

    @typing.override
    async def scrape_episode(self, url: str) -> EpisodePage:
        href = urllib.parse.urlparse(url)
        content = await self.cache.get(f"episodepage:{href}")
        if content is not None:
            return EpisodePage(**json.loads(content.decode(encoding="utf-8")))

        return await self.scraper.scrape_episode(url)
