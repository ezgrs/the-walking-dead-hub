import sqlmodel.ext.asyncio.session
import typing

from twd_hub.domain.models.episode import EpisodeBase
from twd_hub.domain.interfaces.episode_repository import (
    EpisodeRepository as BaseEpisodeRepository,
)
from twd_hub.infrastructure.db.models.episode import EpisodeModel
from twd_hub.infrastructure.db.utils.queries import (
    SQLModelColumnUpdateSpec,
    update_all,
)
from twd_hub.infrastructure.db.utils.tables import (
    SQLModelColumn,
)


class EpisodeRepository(BaseEpisodeRepository):
    session: sqlmodel.ext.asyncio.session.AsyncSession

    def __init__(
        self, session: sqlmodel.ext.asyncio.session.AsyncSession
    ) -> None:
        self.session = session

    @typing.override
    async def update_all(self, datum: list[EpisodeBase]) -> None:
        await update_all(
            self.session,
            EpisodeModel,
            datum,
            index_cols_specs=[
                SQLModelColumnUpdateSpec(
                    col=SQLModelColumn(EpisodeModel, lambda M: M.wiki_href),
                    accessor=lambda data: data.wiki_href,
                ),
            ],
            update_cols_specs=[
                SQLModelColumnUpdateSpec(
                    col=SQLModelColumn(EpisodeModel, lambda M: M.name),
                    accessor=lambda data: data.name,
                ),
                SQLModelColumnUpdateSpec(
                    col=SQLModelColumn(EpisodeModel, lambda M: M.season_number),
                    accessor=lambda data: data.season_number,
                ),
                SQLModelColumnUpdateSpec(
                    col=SQLModelColumn(
                        EpisodeModel, lambda M: M.episode_number
                    ),
                    accessor=lambda data: data.episode_number,
                ),
            ],
        )
