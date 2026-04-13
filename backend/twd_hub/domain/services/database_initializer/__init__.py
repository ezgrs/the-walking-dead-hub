import abc


class DatabaseInitializer(abc.ABC):
    @abc.abstractmethod
    async def run(self) -> None: ...
