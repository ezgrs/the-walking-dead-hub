import sqlmodel.ext.asyncio.session
import typing

from twd_hub.domain.models.entity import EntityBase
from twd_hub.domain.interfaces.entity_repository import (
    EntityRepository as BaseEntityRepository,
)
from twd_hub.infrastructure.db.models.entity import EntityModel
from twd_hub.infrastructure.db.utils.queries import (
    SQLModelColumnUpdateSpec,
    update_all,
)
from twd_hub.infrastructure.db.utils.tables import SQLModelColumn


class EntityRepository(BaseEntityRepository):
    session: sqlmodel.ext.asyncio.session.AsyncSession

    def __init__(
        self, session: sqlmodel.ext.asyncio.session.AsyncSession
    ) -> None:
        self.session = session

    @typing.override
    async def update_all(self, datum: list[EntityBase]) -> None:
        await update_all(
            self.session,
            EntityModel,
            datum,
            index_cols_specs=[
                SQLModelColumnUpdateSpec(
                    col=SQLModelColumn(EntityModel, lambda M: M.wiki_href),
                    accessor=lambda data: data.wiki_href,
                ),
            ],
            update_cols_specs=[
                SQLModelColumnUpdateSpec(
                    col=SQLModelColumn(EntityModel, lambda M: M.name),
                    accessor=lambda data: data.name,
                ),
            ],
        )
