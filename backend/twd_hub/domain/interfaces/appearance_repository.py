import abc

from twd_hub.domain.models.appearance import AppearanceBase, Appearance


class AppearanceRepository(abc.ABC):
    @abc.abstractmethod
    async def read_all(self) -> list[Appearance]: ...

    @abc.abstractmethod
    async def create(self, data: AppearanceBase) -> Appearance: ...
