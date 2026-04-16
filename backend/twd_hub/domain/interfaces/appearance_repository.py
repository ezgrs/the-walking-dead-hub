import abc

from twd_hub.domain.models.entity_appearance import EntityAppearance


class AppearanceRepository(abc.ABC):
    @abc.abstractmethod
    async def update_all(self, datum: list[EntityAppearance]) -> None: ...
