import typing
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


class EntityDataOut(pydantic.BaseModel):
    entity: EntityModel
    appearance_type_label: str
    appearance_form_type_label: str | None


class DataOut(pydantic.BaseModel):
    episode: EpisodeModel
    appearances: list[EntityDataOut]


@router.get("/{season_number}")
async def read_data(
    session: twd_hub.api.dependencies.database_session.Dependency,
    season_number: typing.Annotated[int, fastapi.Path()],
) -> list[DataOut]:
    episodes_mapping: dict[int, EpisodeModel] = {}
    appearances_mapping: dict[int, list[EntityDataOut]] = {}
    for (
        episode,
        entity,
        appearance_type_label,
        appearance_form_type_label,
    ) in await session.exec(
        sqlmodel.select(
            EpisodeModel,
            EntityModel,
            AppearanceTypeModel.name,
            AppearanceFormTypeModel.name,
        )
        .join(
            AppearanceModel,
            sqlmodel.col(AppearanceModel.episode_id) == EpisodeModel.id,
        )
        .join(
            EntityModel,
            sqlmodel.col(EntityModel.id) == AppearanceModel.entity_id,
        )
        .join(
            AppearanceTypeModel,
            sqlmodel.col(AppearanceTypeModel.id) == AppearanceModel.type_id,
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
        .order_by(
            sqlmodel.col(EpisodeModel.season_number),
            sqlmodel.col(EpisodeModel.episode_number),
            sqlmodel.col(EntityModel.id),
        )
    ):
        episodes_mapping.setdefault(episode.episode_number, episode)
        appearances_mapping.setdefault(episode.episode_number, []).append(
            EntityDataOut(
                entity=entity,
                appearance_type_label=appearance_type_label,
                appearance_form_type_label=appearance_form_type_label,
            )
        )
    return [
        DataOut(
            episode=episode,
            appearances=appearances_mapping.get(episode_number, []),
        )
        for episode_number, episode in sorted(
            episodes_mapping.items(), key=lambda i: i[0]
        )
    ]
