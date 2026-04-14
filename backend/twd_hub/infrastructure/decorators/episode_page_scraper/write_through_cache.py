import typing
import urllib.parse
from twd_hub.application.services.episode_page_scraper import EpisodePageScraper
from twd_hub.domain.interfaces.cache_store_service import CacheStore
from twd_hub.domain.models.episode_page import EpisodePage


class WriteThroughCacheEpisodePageScraper(EpisodePageScraper):
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
        episode_page = await self.scraper.scrape(
            url, wait_until_selector=wait_until_selector
        )
        await self.cache.set(
            f"episodepage:{href}",
            episode_page.model_dump_json().encode(encoding="utf-8"),
        )
        return episode_page
