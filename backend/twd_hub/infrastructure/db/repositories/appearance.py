import sqlmodel.ext.asyncio.session
import typing
import sqlalchemy.sql.ddl
import sqlalchemy.dialects.postgresql

from twd_hub.domain.interfaces.appearance_repository import (
    AppearanceRepository as BaseAppearanceRepository,
)
from twd_hub.domain.models.entity_appearance import EntityAppearance
from twd_hub.infrastructure.db.models.appearance import AppearanceModel
from twd_hub.infrastructure.db.models.entity import EntityModel
from twd_hub.infrastructure.db.models.episode import EpisodeModel


class AppearanceRepository(BaseAppearanceRepository):
    session: sqlmodel.ext.asyncio.session.AsyncSession

    def __init__(
        self, session: sqlmodel.ext.asyncio.session.AsyncSession
    ) -> None:
        self.session = session

    @typing.override
    async def update_all(self, datum: list[EntityAppearance]) -> None:
        tmp_table = sqlmodel.Table(
            "tmp_appearances",
            sqlmodel.MetaData(),
            sqlmodel.Column("episodewikihref", sqlmodel.VARCHAR(127)),
            sqlmodel.Column("entitywikihref", sqlmodel.VARCHAR(127)),
            sqlmodel.Column("appearancetypeid", sqlmodel.INTEGER),
            prefixes=["TEMP"],
        )

        # Create table
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
                    "appearancetypeid": data.appearance_type_id,
                }
                for data in datum
            ],
        )

        # Update AppearanceModel from temporary table
        # INSERT INTO appearances (episodeid, entityid, appearancetypeid)
        # SELECT episodes.id, entities.id, tmp_appearances.appearancetypeid FROM tmp_appearances
        # JOIN episodes ON episodes.wikihref = tmp_appearances.episodewikihref
        # JOIN entities ON entities.wikihref = tmp_appearances.entitywikihref
        # ON CONFLICT (episodeid, entityid)
        # DO UPDATE SET appearancetypeid = EXCLUDED.appearancetypeid;
        statement = sqlalchemy.dialects.postgresql.insert(
            AppearanceModel
        ).from_select(
            [
                sqlmodel.col(AppearanceModel.episode_id),
                sqlmodel.col(AppearanceModel.entity_id),
                sqlmodel.col(AppearanceModel.type_id),
            ],
            sqlalchemy.select(
                sqlmodel.col(EpisodeModel.id),
                sqlmodel.col(EntityModel.id),
                tmp_table.c["appearancetypeid"],
            )
            .join(
                EpisodeModel,
                sqlmodel.col(EpisodeModel.wiki_href)
                == tmp_table.c["episodewikihref"],
            )
            .join(
                EntityModel,
                sqlmodel.col(EntityModel.wiki_href)
                == tmp_table.c["entitywikihref"],
            ),
        )
        await self.session.execute(
            statement.on_conflict_do_update(
                index_elements=[
                    sqlmodel.col(AppearanceModel.episode_id),
                    sqlmodel.col(AppearanceModel.entity_id),
                ],
                set_={
                    sqlmodel.col(
                        AppearanceModel.type_id
                    ): statement.excluded.appearancetypeid,
                },
            )
        )

        # Remove outdated rows from AppearanceModel
        # WITH valid_pairs AS (
        #     SELECT episodes.id AS episodeid, entities.id AS entityid
        #     FROM tmp_appearances
        #     JOIN episodes ON episodes.wikihref = tmp_appearances.episodewikihref
        #     JOIN entities ON entities.wikihref = tmp_appearances.entitywikihref
        # )
        # DELETE FROM appearances
        # WHERE NOT EXISTS (
        #     SELECT 1
        #     FROM valid_pairs
        #     WHERE valid_pairs.episodeid = appearances.episodeid
        #     AND valid_pairs.entityid = appearances.entityid
        # );
        valid_pairs = (
            sqlmodel.select(
                sqlmodel.col(EpisodeModel.id).label("episodeid"),
                sqlmodel.col(EntityModel.id).label("entityid"),
            )
            .select_from(tmp_table)
            .join(
                EpisodeModel,
                sqlmodel.col(EpisodeModel.wiki_href)
                == tmp_table.c["episodewikihref"],
            )
            .join(
                EntityModel,
                sqlmodel.col(EntityModel.wiki_href)
                == tmp_table.c["entitywikihref"],
            )
            .cte()
        )
        await self.session.execute(
            sqlmodel.delete(AppearanceModel).where(
                ~sqlmodel.select(1)
                .select_from(valid_pairs)
                .where(
                    sqlmodel.and_(
                        valid_pairs.c["episodeid"]
                        == AppearanceModel.episode_id,
                        valid_pairs.c["entityid"] == AppearanceModel.entity_id,
                    )
                )
                .exists()
            )
        )
        await self.session.commit()
