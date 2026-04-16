import pydantic


class EntityAppearanceBase(pydantic.BaseModel):
    entity_page_href: str
    entity_page_title: str
    entity_name: str

    appearance_type_id: int
    appearance_form_types_ids: list[int]


class EntityAppearance(EntityAppearanceBase):
    episode_page_href: str
