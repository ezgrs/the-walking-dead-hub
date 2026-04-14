import pydantic

from twd_hub.domain.models.entity_appearance import EntityAppearance
from twd_hub.domain.models.episode import EpisodeBase


class EpisodePage(pydantic.BaseModel):
    episode: EpisodeBase
    entity_appearances: list[EntityAppearance]
    next_page_href: str
