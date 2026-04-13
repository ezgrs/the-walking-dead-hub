import sqlmodel.ext.asyncio.session
import typing

from twd_hub.domain.models.entity import EntityBase, Entity
from twd_hub.domain.interfaces.entity_repository import (
    EntityRepository as BaseEntityRepository,
)
from twd_hub.infrastructure.db.models.entity import EntityModel


class EntityRepository(BaseEntityRepository):
    session: sqlmodel.ext.asyncio.session.AsyncSession

    def __init__(
        self, session: sqlmodel.ext.asyncio.session.AsyncSession
    ) -> None:
        self.session = session

    @typing.override
    async def read_all(self) -> list[Entity]:
        return [
            Entity(
                id=typing.cast(int, model.id),
                name=model.name,
                wiki_href=model.wiki_href,
            )
            for model in await self.session.exec(sqlmodel.select(EntityModel))
        ]

    @typing.override
    async def create(self, data: EntityBase) -> Entity:
        model = EntityModel(
            id=None,
            name=data.name,
            wiki_href=data.wiki_href,
        )
        self.session.add(model)
        await self.session.flush([model])
        return Entity(
            id=typing.cast(int, model.id),
            name=model.name,
            wiki_href=model.wiki_href,
        )
