import abc

from twd_hub.domain.models.entity import EntityBase, Entity


class EntityRepository(abc.ABC):
    @abc.abstractmethod
    async def read_all(self) -> list[Entity]: ...

    @abc.abstractmethod
    async def create(self, data: EntityBase) -> Entity: ...
