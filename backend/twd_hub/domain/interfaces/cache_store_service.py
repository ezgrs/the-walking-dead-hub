import abc


class CacheStore(abc.ABC):
    @abc.abstractmethod
    async def get(self, key: str) -> bytes | None: ...

    @abc.abstractmethod
    async def set(self, key: str, value: bytes) -> None: ...
