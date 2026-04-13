import re
import typing
import bs4
from . import TagParser as BaseTagParser
from twd_hub.domain.models import EpisodePage, EntityAppearance


class TagParser(BaseTagParser[EpisodePage]):
    EPISODE_NUMBER_PATTERN: typing.ClassVar[re.Pattern] = re.compile(
        r"^Season ([0-9]+), Episode ([0-9]+)$"
    )

    entity_appearance_parser: BaseTagParser[EntityAppearance | None]

    def __init__(
        self,
        *,
        entity_appearance_parser: BaseTagParser[EntityAppearance | None],
    ) -> None:
        self.entity_appearance_parser = entity_appearance_parser

    @typing.override
    async def parse(self, element: bs4.Tag) -> EpisodePage:
        # Parse episode URL
        link_elem = element.find("link", {"rel": "canonical"})
        if link_elem is None:
            raise ValueError("no episode link found")
        episode_href = link_elem["href"]
        if not isinstance(episode_href, str):
            raise ValueError(f"invalid episode link: {episode_href}")
        episode_href = episode_href.removeprefix(
            "https://walkingdead.fandom.com"
        )

        # Parse episode title
        episode_title_elem = element.find("h2", {"data-source": "title"})
        if episode_title_elem is None:
            raise ValueError("no episode title found")
        episode_title = episode_title_elem.get_text()

        # Parse episode season and number
        episode_number_description_elem = element.find(
            "div", {"data-source": "number"}
        )
        if episode_number_description_elem is None:
            raise ValueError("no episode number found")
        episode_number_description_elem_text = (
            episode_number_description_elem.get_text().strip()
        )
        episode_number_description_match = self.EPISODE_NUMBER_PATTERN.match(
            episode_number_description_elem_text
        )
        if episode_number_description_match is None:
            raise ValueError(
                f"invalid episode number: {episode_number_description_elem_text}"
            )

        episode_season_text, episode_number_text = (
            episode_number_description_match.groups()
        )
        episode_season = int(episode_season_text)
        episode_number = int(episode_number_text)

        # Parse episode entity appearances
        entity_appearances: list[EntityAppearance] = []
        trivia_elem = element.select_one("#Trivia")
        assert trivia_elem
        trivia_ul_elem = trivia_elem.find_next("ul")
        assert trivia_ul_elem
        for trivia_li_elem in trivia_ul_elem.select("li"):
            entity_appearance = await self.entity_appearance_parser.parse(
                trivia_li_elem
            )
            if entity_appearance is None:
                continue
            entity_appearances.append(entity_appearance)

        # Parse Next episode
        next_page_elem = element.find("td", {"data-source": "next"})
        assert next_page_elem
        next_page_a_elem = next_page_elem.find("a")
        assert next_page_a_elem
        next_page_href = next_page_a_elem["href"]
        assert isinstance(next_page_href, str)

        return EpisodePage(
            href=episode_href,
            title=episode_title,
            season_number=episode_season,
            episode_number=episode_number,
            entity_appearances=entity_appearances,
            next_page_href=next_page_href,
        )
