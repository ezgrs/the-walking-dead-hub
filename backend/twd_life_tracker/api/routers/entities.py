import typing
import fastapi
import pydantic
import sqlmodel
import http.client

from twd_life_tracker.infrastructure.db.models.appearance import (
    AppearanceModel,
)
from twd_life_tracker.infrastructure.db.models.appearance_form import (
    AppearanceFormModel,
)
from twd_life_tracker.infrastructure.db.models.appearance_form_type import (
    AppearanceFormTypeModel,
)
from twd_life_tracker.infrastructure.db.models.appearance_type import (
    AppearanceTypeModel,
)
from twd_life_tracker.infrastructure.db.models.entity import EntityModel
from twd_life_tracker.infrastructure.db.models.episode import (
    EpisodeModel,
)
import twd_life_tracker.api.dependencies.database_session

router = fastapi.APIRouter()


class IndexOut(pydantic.BaseModel):
    index: str
    count: int


@router.get("/indices")
async def read_indices(
    session: twd_life_tracker.api.dependencies.database_session.Dependency,
) -> list[IndexOut]:
    index_stmt = sqlmodel.func.upper(
        sqlmodel.func.substring(EntityModel.name, 1, 1)
    )

    return [
        IndexOut(
            index=index,
            count=count,
        )
        for index, count in await session.exec(
            sqlmodel.select(index_stmt, sqlmodel.func.count())
            .group_by(index_stmt)
            .order_by(index_stmt)
        )
    ]


@router.get("/")
async def read_all(
    session: twd_life_tracker.api.dependencies.database_session.Dependency,
    index: typing.Annotated[
        str, fastapi.Query(min_length=1, max_length=1)
    ] = "A",
) -> list[EntityModel]:
    return [
        *await session.exec(
            sqlmodel.select(EntityModel)
            .where(sqlmodel.col(EntityModel.name).startswith(index.upper()))
            .order_by(EntityModel.name)
        )
    ]


class EpisodeDataOut(pydantic.BaseModel):
    episode: EpisodeModel
    appearance_type_label: str
    appearance_form_type_label: str | None


class DataOut(pydantic.BaseModel):
    entity: EntityModel
    episodes: list[EpisodeDataOut]


@router.get("/{entity_id}")
async def read_data(
    session: twd_life_tracker.api.dependencies.database_session.Dependency,
    entity_id: typing.Annotated[int, fastapi.Path()],
) -> DataOut:
    entity_model = (
        await session.exec(
            sqlmodel.select(EntityModel)
            .where(EntityModel.id == entity_id)
            .limit(1)
        )
    ).one_or_none()
    if entity_model is None:
        raise fastapi.HTTPException(status_code=http.client.NOT_FOUND)
    return DataOut(
        entity=entity_model,
        episodes=[
            EpisodeDataOut(
                episode=episode,
                appearance_type_label=appearance_type_label,
                appearance_form_type_label=appearance_form_type_label,
            )
            for (
                episode,
                appearance_type_label,
                appearance_form_type_label,
            ) in await session.exec(
                sqlmodel.select(
                    EpisodeModel,
                    AppearanceTypeModel.name,
                    AppearanceFormTypeModel.name,
                )
                .join(
                    AppearanceModel,
                    sqlmodel.col(AppearanceModel.episode_id) == EpisodeModel.id,
                )
                .join(
                    AppearanceTypeModel,
                    sqlmodel.col(AppearanceTypeModel.id)
                    == AppearanceModel.type_id,
                )
                .outerjoin(
                    AppearanceFormModel,
                    sqlmodel.col(AppearanceFormModel.appearance_id)
                    == AppearanceModel.id,
                )
                .outerjoin(
                    AppearanceFormTypeModel,
                    sqlmodel.col(AppearanceFormTypeModel.id)
                    == AppearanceFormModel.type_id,
                )
                .where(AppearanceModel.entity_id == entity_id)
                .order_by(
                    sqlmodel.col(EpisodeModel.season_number),
                    sqlmodel.col(EpisodeModel.episode_number),
                )
            )
        ],
    )
