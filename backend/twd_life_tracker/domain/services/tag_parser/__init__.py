import abc

import bs4

from twd_life_tracker.domain.models import EntityAppearance, EpisodePage
from twd_life_tracker.domain.interfaces.alias_repository import AliasRepository


class TagParser[T](abc.ABC):
    @classmethod
    def episode_page(
        cls,
        *,
        entity_appearance_parser: "TagParser[EntityAppearance | None]",
    ) -> "TagParser[EpisodePage]":
        from .episode_page import TagParser

        return TagParser(entity_appearance_parser=entity_appearance_parser)

    @classmethod
    def entity_appearance(
        cls, *, alias_repository: AliasRepository
    ) -> "TagParser[EntityAppearance | None]":
        from .entity_appearance import TagParser

        return TagParser(alias_repository=alias_repository)

    @abc.abstractmethod
    async def parse(self, element: bs4.Tag) -> T: ...
