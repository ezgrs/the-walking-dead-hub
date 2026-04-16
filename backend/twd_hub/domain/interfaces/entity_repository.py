import abc

from twd_hub.domain.models.entity import EntityBase


class EntityRepository(abc.ABC):
    @abc.abstractmethod
    async def update_all(self, datum: list[EntityBase]) -> None: ...
