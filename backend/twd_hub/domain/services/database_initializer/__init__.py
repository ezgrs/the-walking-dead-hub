import abc
import typing


class DatabaseInitializer(abc.ABC):
    @abc.abstractmethod
    async def run(
        self, initial_page_href: str, *, until: typing.Optional[tuple[int, int]]
    ) -> None: ...
