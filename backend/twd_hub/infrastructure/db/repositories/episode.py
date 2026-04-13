import sqlmodel.ext.asyncio.session
import typing

from twd_hub.domain.models.episode import EpisodeBase, Episode
from twd_hub.domain.interfaces.episode_repository import (
    EpisodeRepository as BaseEpisodeRepository,
)
from twd_hub.infrastructure.db.models.episode import EpisodeModel


class EpisodeRepository(BaseEpisodeRepository):
    session: sqlmodel.ext.asyncio.session.AsyncSession

    def __init__(
        self, session: sqlmodel.ext.asyncio.session.AsyncSession
    ) -> None:
        self.session = session

    @typing.override
    async def read_all(self) -> list[Episode]:
        return [
            Episode(
                id=typing.cast(int, model.id),
                season_number=model.season_number,
                episode_number=model.episode_number,
                name=model.name,
                wiki_href=model.wiki_href,
            )
            for model in await self.session.exec(sqlmodel.select(EpisodeModel))
        ]

    @typing.override
    async def create(self, data: EpisodeBase) -> Episode:
        model = EpisodeModel(
            id=None,
            season_number=data.season_number,
            episode_number=data.episode_number,
            name=data.name,
            wiki_href=data.wiki_href,
        )
        self.session.add(model)
        await self.session.flush([model])
        return Episode(
            id=typing.cast(int, model.id),
            season_number=model.season_number,
            episode_number=model.episode_number,
            name=model.name,
            wiki_href=model.wiki_href,
        )
