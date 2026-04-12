import typing

import sqlmodel
import sqlmodel.ext.asyncio.session


from twd_life_tracker.domain.interfaces.alias_repository import (
    AliasRepository as BaseAliasRepository,
)
from twd_life_tracker.infrastructure.db.models.appearance_form_type import (
    AppearanceFormTypeModel,
)
from twd_life_tracker.infrastructure.db.models.appearance_form_type_alias import (
    AppearanceFormTypeAliasModel,
)
from twd_life_tracker.infrastructure.db.models.appearance_type import (
    AppearanceTypeModel,
)
from twd_life_tracker.infrastructure.db.models.appearance_type_alias import (
    AppearanceTypeAliasModel,
)


class AliasRepository(BaseAliasRepository):
    session: sqlmodel.ext.asyncio.session.AsyncSession

    def __init__(
        self, session: sqlmodel.ext.asyncio.session.AsyncSession
    ) -> None:
        self.session = session

    @typing.override
    async def find_appearance_order_id(self, text: str) -> int | None:
        return (
            await self.session.exec(
                sqlmodel.select(AppearanceTypeModel.id)
                .join(
                    AppearanceTypeAliasModel,
                    sqlmodel.col(AppearanceTypeModel.id)
                    == AppearanceTypeAliasModel.ref_id,
                )
                .where(
                    sqlmodel.bindparam("text").like(
                        AppearanceTypeAliasModel.label + "%"
                    )
                ),
                params={"text": text},
            )
        ).one_or_none()

    @typing.override
    async def find_character_statuses_ids(
        self, aliases: typing.Sequence[str]
    ) -> list[int | None]:
        aliases_table = sqlmodel.values(
            sqlmodel.column("idx", sqlmodel.Integer),
            sqlmodel.column("label", sqlmodel.String),
        ).data(
            [(i, label) for i, label in enumerate(aliases)]
        ).alias("aliases")

        return [*await self.session.exec(
            sqlmodel
            .select(AppearanceFormTypeModel.id)
            .select_from(aliases_table)
            .outerjoin(
                AppearanceFormTypeAliasModel,
                sqlmodel.col(AppearanceFormTypeAliasModel.label) == aliases_table.c.label,
            )
            .join(
                AppearanceFormTypeModel,
                sqlmodel.col(AppearanceFormTypeModel.id) == AppearanceFormTypeAliasModel.ref_id,
            )
            .order_by(aliases_table.c.idx)
        )]
