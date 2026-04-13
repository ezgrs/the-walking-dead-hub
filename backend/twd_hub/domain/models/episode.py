import pydantic


class EpisodeBase(pydantic.BaseModel):
    name: str
    wiki_href: str
    season_number: int
    episode_number: int


class Episode(EpisodeBase):
    id: int
