import sqlmodel.ext.asyncio.session
import typing

from twd_hub.domain.models.appearance import AppearanceBase, Appearance
from twd_hub.domain.interfaces.appearance_repository import (
    AppearanceRepository as BaseAppearanceRepository,
)
from twd_hub.infrastructure.db.models.appearance import AppearanceModel


class AppearanceRepository(BaseAppearanceRepository):
    session: sqlmodel.ext.asyncio.session.AsyncSession

    def __init__(
        self, session: sqlmodel.ext.asyncio.session.AsyncSession
    ) -> None:
        self.session = session

    @typing.override
    async def read_all(self) -> list[Appearance]:
        return [
            Appearance(
                id=typing.cast(int, model.id),
                episode_id=model.episode_id,
                entity_id=model.entity_id,
                type_id=model.type_id,
            )
            for model in await self.session.exec(
                sqlmodel.select(AppearanceModel)
            )
        ]

    @typing.override
    async def create(self, data: AppearanceBase) -> Appearance:
        model = AppearanceModel(
            id=None,
            episode_id=data.episode_id,
            entity_id=data.entity_id,
            type_id=data.type_id,
        )
        self.session.add(model)
        await self.session.flush([model])
        return Appearance(
            id=typing.cast(int, model.id),
            episode_id=model.episode_id,
            entity_id=model.entity_id,
            type_id=model.type_id,
        )
