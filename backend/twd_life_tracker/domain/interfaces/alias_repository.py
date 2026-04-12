import abc
import typing


class AliasRepository(abc.ABC):
    @abc.abstractmethod
    async def find_appearance_order_id(self, text: str) -> int | None: ...

    @abc.abstractmethod
    async def find_character_statuses_ids(
        self, aliases: typing.Sequence[str]
    ) -> list[int | None]: ...
