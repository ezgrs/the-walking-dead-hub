import abc
import typing
from twd_hub.domain.interfaces.html_loader_service import HtmlLoader
from twd_hub.domain.interfaces.html_parser_service import HtmlParser
from twd_hub.domain.models.episode_page import EpisodePage


class EpisodePageScraper(abc.ABC):
    @abc.abstractmethod
    async def scrape(
        self, url: str, *, wait_until_selector: str | None = None
    ) -> EpisodePage: ...


class DefaultEpisodePageScraper(EpisodePageScraper):
    html_loader: HtmlLoader
    html_parser: HtmlParser

    def __init__(
        self, *, html_loader: HtmlLoader, html_parser: HtmlParser
    ) -> None:
        self.html_loader = html_loader
        self.html_parser = html_parser

    @typing.override
    async def scrape(
        self, url: str, *, wait_until_selector: str | None = None
    ) -> EpisodePage:
        html_data = await self.html_loader.load(
            url, wait_until_selector=wait_until_selector
        )
        return await self.html_parser.parse_episode_page(html_data)
