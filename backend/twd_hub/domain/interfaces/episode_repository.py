import abc

from twd_hub.domain.models.episode import EpisodeBase, Episode


class EpisodeRepository(abc.ABC):
    @abc.abstractmethod
    async def read_all(self) -> list[Episode]: ...

    @abc.abstractmethod
    async def create(self, data: EpisodeBase) -> Episode: ...
