import re
import typing

import bs4
from twd_hub.domain.interfaces.alias_repository import AliasRepository
from twd_hub.domain.interfaces.html_parser_service import HtmlParser
from twd_hub.domain.models.entity_appearance import EntityAppearance
from twd_hub.domain.models.episode import EpisodeBase
from twd_hub.domain.models.episode_page import EpisodePage


class Bs4HtmlParser(HtmlParser):
    EPISODE_NUMBER_PATTERN: typing.ClassVar[re.Pattern] = re.compile(
        r"^Season ([0-9]+), Episode ([0-9]+)$"
    )

    alias_repository: AliasRepository

    def __init__(self, *, alias_repository: AliasRepository) -> None:
        self.alias_repository = alias_repository

    def _get_tag(self, html_data: str) -> bs4.Tag:
        return bs4.BeautifulSoup(html_data, features="html.parser")

    @typing.override
    async def parse_episode_page(self, html_data: str) -> EpisodePage:
        element = self._get_tag(html_data)

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
            entity_appearance = await self._parse_entity_appearance(
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
            episode=EpisodeBase(
                name=episode_title,
                wiki_href=episode_href,
                season_number=episode_season,
                episode_number=episode_number,
            ),
            entity_appearances=entity_appearances,
            next_page_href=next_page_href,
        )

    async def _parse_entity_appearance(
        self, element: bs4.Tag
    ) -> EntityAppearance | None:
        text = element.get_text()
        appearance_order_id = (
            await self.alias_repository.find_appearance_type_id(text)
        )
        if appearance_order_id is None:
            return None

        a_elem = element.find("a")
        assert a_elem is not None

        split_pattern = re.compile(", |/")
        i_elem = element.find("i")
        appearance_types_ids: list[int] = []
        if i_elem is not None:
            character_status_texts = split_pattern.split(
                i_elem.get_text().removeprefix("(").removesuffix(")")
            )
            for appearance_type_alias, appearance_type_id in zip(
                character_status_texts,
                await self.alias_repository.find_appearance_form_types_ids(
                    character_status_texts
                ),
            ):
                if appearance_type_id is None:
                    raise ValueError(
                        f"invalid appearance type text: {appearance_type_alias}"
                    )
                appearance_types_ids.append(appearance_type_id)

        character_a_href = a_elem.get("href")
        assert isinstance(
            character_a_href, str
        ), f"invalid character_a_href: {character_a_href}"

        character_a_title = a_elem.get("title")
        assert isinstance(
            character_a_title, str
        ), f"invalid character_a_title: {character_a_title}"

        character_name = a_elem.get_text().strip()
        return EntityAppearance(
            entity_page_href=character_a_href,
            entity_page_title=character_a_title,
            entity_name=character_name,
            appearance_type_id=appearance_order_id,
            appearance_form_types_ids=appearance_types_ids,
        )
