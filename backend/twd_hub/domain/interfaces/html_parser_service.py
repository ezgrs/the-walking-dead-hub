import abc

from twd_hub.domain.models.episode_page import EpisodePage


class HtmlParser(abc.ABC):
    @abc.abstractmethod
    async def parse_episode_page(self, html_data: str) -> EpisodePage: ...
