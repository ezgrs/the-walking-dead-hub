import abc

from twd_hub.domain.models.appearance_form import (
    AppearanceFormBase,
    AppearanceForm,
)


class AppearanceFormRepository(abc.ABC):
    @abc.abstractmethod
    async def read_all(self) -> list[AppearanceForm]: ...

    @abc.abstractmethod
    async def create(self, data: AppearanceFormBase) -> AppearanceForm: ...
