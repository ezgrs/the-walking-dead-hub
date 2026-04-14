import abc
import typing


class HtmlLoader(typing.AsyncContextManager, abc.ABC):
    @abc.abstractmethod
    async def load(
        self, url: str, *, wait_until_selector: str | None = None
    ) -> str: ...
