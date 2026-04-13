import pydantic


class AppearanceBase(pydantic.BaseModel):
    episode_id: int
    entity_id: int
    type_id: int


class Appearance(AppearanceBase):
    id: int
