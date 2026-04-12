import dataclasses

import pydantic


@dataclasses.dataclass(kw_only=True, frozen=True)
class EntityAppearance:
    entity_page_href: str
    entity_page_title: str
    entity_name: str

    appearance_type_id: int
    appearance_form_types_ids: list[int]


class EpisodePage(pydantic.BaseModel):
    href: str
    title: str
    season_number: int
    episode_number: int
    entity_appearances: list[EntityAppearance]
    next_page_href: str
