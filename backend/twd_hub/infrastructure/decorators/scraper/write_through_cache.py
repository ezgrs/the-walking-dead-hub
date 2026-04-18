import typing
import urllib.parse
from twd_hub.application.services.scraper import Scraper
from twd_hub.domain.interfaces.cache_store_service import CacheStore
from twd_hub.domain.models.episode_page import EpisodePage


class WriteThroughCacheScraper(Scraper):
    scraper: Scraper
    cache: CacheStore

    def __init__(self, scraper: Scraper, *, cache: CacheStore) -> None:
        self.scraper = scraper
        self.cache = cache

    @typing.override
    async def scrape_episode(self, url: str) -> EpisodePage:
        href = urllib.parse.urlparse(url)
        episode_page = await self.scraper.scrape_episode(url)
        await self.cache.set(
            f"episodepage:{href}",
            episode_page.model_dump_json().encode(encoding="utf-8"),
        )
        return episode_page
