import abc

from twd_hub.domain.models.episode import EpisodeBase


class EpisodeRepository(abc.ABC):
    @abc.abstractmethod
    async def update_all(self, datum: list[EpisodeBase]) -> None: ...
