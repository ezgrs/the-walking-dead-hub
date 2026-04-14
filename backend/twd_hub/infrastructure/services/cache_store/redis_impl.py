import typing

import redis.asyncio

from twd_hub.domain.interfaces.cache_store_service import CacheStore


class RedisCacheStore(CacheStore):
    r: redis.asyncio.Redis

    def __init__(self, r: redis.asyncio.Redis) -> None:
        self.r = r

    @typing.override
    async def get(self, key: str) -> bytes | None:
        return await self.r.get(key)

    @typing.override
    async def set(self, key: str, value: bytes) -> None:
        await self.r.set(key, value, ex=86400)
