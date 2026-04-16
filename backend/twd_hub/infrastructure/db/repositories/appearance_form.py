import sqlmodel.ext.asyncio.session
import typing
import sqlalchemy.sql.ddl
from twd_hub.domain.interfaces.appearance_form_repository import (
    AppearanceFormRepository as BaseAppearanceFormRepository,
)
from twd_hub.domain.models.entity_appearance import EntityAppearance
from twd_hub.infrastructure.db.models.appearance import AppearanceModel
from twd_hub.infrastructure.db.models.appearance_form import AppearanceFormModel
from twd_hub.infrastructure.db.models.entity import EntityModel
from twd_hub.infrastructure.db.models.episode import EpisodeModel


class AppearanceFormRepository(BaseAppearanceFormRepository):
    session: sqlmodel.ext.asyncio.session.AsyncSession

    def __init__(
        self, session: sqlmodel.ext.asyncio.session.AsyncSession
    ) -> None:
        self.session = session

    @typing.override
    async def update_all(self, datum: list[EntityAppearance]) -> None:
        tmp_table = sqlmodel.Table(
            "tmp_appearanceforms",
            sqlmodel.MetaData(),
            sqlmodel.Column("episodewikihref", sqlmodel.VARCHAR(127)),
            sqlmodel.Column("entitywikihref", sqlmodel.VARCHAR(127)),
            sqlmodel.Column("appearanceformtypeid", sqlmodel.INTEGER),
            prefixes=["TEMP"],
        )
        await self.session.execute(
            sqlmodel.text(
                str(
                    sqlalchemy.sql.ddl.CreateTable(tmp_table).compile(
                        compile_kwargs={"literal_binds": True}
                    )
                ).removesuffix("\n\n")
                + " ON COMMIT DROP;\n\n"
            )
        )

        await self.session.execute(
            tmp_table.insert(),
            [
                {
                    "episodewikihref": data.episode_page_href,
                    "entitywikihref": data.entity_page_href,
                    "appearanceformtypeid": appearance_form_type_id,
                }
                for data in datum
                for appearance_form_type_id in data.appearance_form_types_ids
            ],
        )

        await self.session.execute(sqlmodel.text(f"TRUNCATE {AppearanceFormModel.__tablename__} RESTART IDENTITY"))

        await self.session.execute(
            sqlmodel.insert(AppearanceFormModel)
            .from_select(
                [
                    sqlmodel.col(AppearanceFormModel.appearance_id),
                    sqlmodel.col(AppearanceFormModel.type_id),
                ],
                sqlmodel
                .select(
                    sqlmodel.col(AppearanceModel.id),
                    tmp_table.c["appearanceformtypeid"],
                )
                .join(
                    EpisodeModel,
                    sqlmodel.col(EpisodeModel.wiki_href) ==  tmp_table.c["episodewikihref"],
                )
                .join(
                    EntityModel,
                    sqlmodel.col(EntityModel.wiki_href) ==  tmp_table.c["entitywikihref"],
                )
                .join(
                    AppearanceModel,
                    sqlmodel.and_(
                        sqlmodel.col(AppearanceModel.episode_id) == EpisodeModel.id,
                        sqlmodel.col(AppearanceModel.entity_id) == EntityModel.id,
                    ),

                )
            )
        )
        await self.session.commit()
        
