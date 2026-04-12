import re
import typing
import bs4
from . import TagParser as BaseTagParser
from twd_life_tracker.domain.models import EntityAppearance
from twd_life_tracker.domain.interfaces.alias_repository import AliasRepository


class TagParser(BaseTagParser[EntityAppearance | None]):
    alias_repository: AliasRepository

    def __init__(self, *, alias_repository: AliasRepository) -> None:
        self.alias_repository = alias_repository

    @typing.override
    async def parse(self, element: bs4.Tag) -> EntityAppearance | None:
        text = element.get_text()
        appearance_order_id = (
            await self.alias_repository.find_appearance_order_id(text)
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
                await self.alias_repository.find_character_statuses_ids(
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
