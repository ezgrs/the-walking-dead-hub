import abc
import typing


class DatabaseInitializer(abc.ABC):
    @abc.abstractmethod
    async def run(self, *, until: typing.Optional[tuple[int, int]]) -> None: ...
