import pydantic

from twd_hub.domain.models.entity_appearance import EntityAppearanceBase
from twd_hub.domain.models.episode import EpisodeBase


class EpisodePage(pydantic.BaseModel):
    episode: EpisodeBase
    entity_appearances: list[EntityAppearanceBase]
    next_page_href: str | None
