import pydantic


class EntityBase(pydantic.BaseModel):
    name: str
    wiki_href: str


class Entity(EntityBase):
    id: int
