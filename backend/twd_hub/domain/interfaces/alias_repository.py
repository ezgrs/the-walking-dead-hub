import abc
import typing


class AliasRepository(abc.ABC):
    @abc.abstractmethod
    async def find_appearance_type_id(self, text: str) -> int | None: ...

    @abc.abstractmethod
    async def find_appearance_form_types_ids(
        self, aliases: typing.Sequence[str]
    ) -> list[int | None]: ...
