import hashlib
import aiopath

from twd_hub.domain.interfaces.cache_store_service import CacheStore


class AiopathCacheStore(CacheStore):
    def __init__(self, base_dir: aiopath.AsyncPath):
        self.base_dir = base_dir

    def _key_to_path(self, key: str) -> aiopath.AsyncPath:
        safe_key = hashlib.sha256(key.encode("utf-8")).hexdigest()
        return self.base_dir / f"{safe_key}.bin"

    async def get(self, key: str) -> bytes | None:
        path = self._key_to_path(key)
        if not await path.exists():
            return None

        try:
            return await path.read_bytes()
        except FileNotFoundError:
            return None

    async def set(self, key: str, value: bytes) -> None:
        path = self._key_to_path(key)
        await path.parent.mkdir(parents=True, exist_ok=True)
        await path.write_bytes(value)
