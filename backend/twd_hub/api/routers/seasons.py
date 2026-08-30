import typing
import http.client

import fastapi
import pydantic
import sqlmodel

from twd_hub.infrastructure.db.models.appearance import (
    AppearanceModel,
)
from twd_hub.infrastructure.db.models.appearance_form import (
    AppearanceFormModel,
)
from twd_hub.infrastructure.db.models.appearance_form_type import (
    AppearanceFormTypeModel,
)
from twd_hub.infrastructure.db.models.appearance_type import (
    AppearanceTypeModel,
)
from twd_hub.infrastructure.db.models.entity import EntityModel
from twd_hub.infrastructure.db.models.episode import (
    EpisodeModel,
)
import twd_hub.api.dependencies.database_session

router = fastapi.APIRouter()


class IndexOut(pydantic.BaseModel):
    index: int
    count: int


@router.get("/indices")
async def read_indices(
    session: twd_hub.api.dependencies.database_session.Dependency,
) -> list[IndexOut]:
    return [
        IndexOut(
            index=index,
            count=count,
        )
        for index, count in await session.exec(
            sqlmodel.select(EpisodeModel.season_number, sqlmodel.func.count())
            .group_by(sqlmodel.col(EpisodeModel.season_number))
            .order_by(sqlmodel.col(EpisodeModel.season_number))
        )
    ]


@router.get("")
async def read_all(
    session: twd_hub.api.dependencies.database_session.Dependency,
    index: typing.Annotated[
        int, fastapi.Query(ge=1)
    ] = 1,
) -> list[EpisodeModel]:
    return [
        *await session.exec(
            sqlmodel.select(EpisodeModel)
            .where(sqlmodel.col(EpisodeModel.season_number) == index)
            .order_by(sqlmodel.col(EpisodeModel.episode_number))
        )
    ]


class SeasonEpisodeAppearanceDto(pydantic.BaseModel):
    entity: EntityModel
    appearance_type_label: str
    appearance_form_type_label: str | None


class SeasonEpisodeDto(pydantic.BaseModel):
    episode: EpisodeModel
    appearances: list[SeasonEpisodeAppearanceDto]


@router.get("/{season_number}/{episode_number}")
async def read_data(
    session: twd_hub.api.dependencies.database_session.Dependency,
    season_number: typing.Annotated[int, fastapi.Path()],
    episode_number: typing.Annotated[int, fastapi.Path()],
) -> SeasonEpisodeDto:
    episode_model = (
        await session.exec(
            sqlmodel.select(EpisodeModel)
            .where(EpisodeModel.season_number == season_number)
            .where(EpisodeModel.episode_number == episode_number)
            .limit(1)
        )
    ).one_or_none()
    if episode_model is None:
        raise fastapi.HTTPException(status_code=http.client.NOT_FOUND)
    return SeasonEpisodeDto(
        episode=episode_model,
        appearances=[
            SeasonEpisodeAppearanceDto(
                entity=entity,
                appearance_type_label=appearance_type_label,
                appearance_form_type_label=appearance_form_type_label,
            )
            for (
                entity,
                appearance_type_label,
                appearance_form_type_label,
            ) in await session.exec(
                sqlmodel.select(
                    EntityModel,
                    AppearanceTypeModel.name,
                    AppearanceFormTypeModel.name,
                )
                .join(
                    AppearanceModel,
                    sqlmodel.col(AppearanceModel.entity_id) == EntityModel.id,
                )
                .join(
                    EpisodeModel,
                    sqlmodel.col(EpisodeModel.id) == AppearanceModel.episode_id,
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
                .where(sqlmodel.col(EpisodeModel.season_number) == season_number)
                .where(sqlmodel.col(EpisodeModel.episode_number) == episode_number)
            )
        ],
    )
    