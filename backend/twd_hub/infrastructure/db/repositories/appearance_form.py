import sqlmodel.ext.asyncio.session
import typing

from twd_hub.domain.models.appearance_form import (
    AppearanceFormBase,
    AppearanceForm,
)
from twd_hub.domain.interfaces.appearance_form_repository import (
    AppearanceFormRepository as BaseAppearanceFormRepository,
)
from twd_hub.infrastructure.db.models.appearance_form import AppearanceFormModel


class AppearanceFormRepository(BaseAppearanceFormRepository):
    session: sqlmodel.ext.asyncio.session.AsyncSession

    def __init__(
        self, session: sqlmodel.ext.asyncio.session.AsyncSession
    ) -> None:
        self.session = session

    @typing.override
    async def read_all(self) -> list[AppearanceForm]:
        return [
            AppearanceForm(
                id=typing.cast(int, model.id),
                appearance_id=model.appearance_id,
                type_id=model.type_id,
            )
            for model in await self.session.exec(
                sqlmodel.select(AppearanceFormModel)
            )
        ]

    @typing.override
    async def create(self, data: AppearanceFormBase) -> AppearanceForm:
        model = AppearanceFormModel(
            id=None,
            appearance_id=data.appearance_id,
            type_id=data.type_id,
        )
        self.session.add(model)
        await self.session.flush([model])
        return AppearanceForm(
            id=typing.cast(int, model.id),
            appearance_id=model.appearance_id,
            type_id=model.type_id,
        )
