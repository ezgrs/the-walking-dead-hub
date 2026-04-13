import argparse
import asyncio
import os
import pathlib
import typing
import aiopath
import redis.asyncio

from twd_life_tracker.domain.interfaces.alias_repository import AliasRepository
from twd_life_tracker.domain.interfaces.import_repository import ImportRepository
from twd_life_tracker.domain.models.settings import Settings
from twd_life_tracker.domain.services.episode_page_loader import EpisodeLoader
from twd_life_tracker.domain.services.page_loader import PageLoader
from twd_life_tracker.domain.services.tag_parser import TagParser



async def run(
    cache: redis.asyncio.Redis,
    alias_repository: AliasRepository,
    import_repository: ImportRepository,
    cache_dir_path: os.PathLike | None = None,
) -> None:
    page_loader = PageLoader.from_server()
    if cache_dir_path is not None:
        dpath = aiopath.Path(cache_dir_path)
        page_loader = page_loader.with_write_through_cache(dpath).with_read_through_cache(
            dpath
        )

    episode_loader = (
        EpisodeLoader.from_server(
            page_loader=page_loader,
            tag_parser=TagParser.episode_page(
                entity_appearance_parser=TagParser.entity_appearance(
                    alias_repository=alias_repository,
                ),
            ),
        )
        .with_write_through_cache(cache)
        .with_read_through_cache(cache)
    )

    async with page_loader:
        await import_repository.import_data(loader=episode_loader)


def _parse_sys_args() -> argparse.Namespace:
    def _type(path_str: str) -> os.PathLike:
        path = pathlib.Path(path_str)
        path.mkdir(parents=True, exist_ok=True)
        return path

    parser = argparse.ArgumentParser(description="Import data script")
    parser.add_argument(
        "--cache-dir",
        type=_type,
        required=False,
        help="Path to cache directory",
    )
    return parser.parse_args()

async def _main() -> None:
    from twd_life_tracker.infrastructure.db.session import create_engine
    from twd_life_tracker.infrastructure.db.repositories.alias import AliasRepository
    from twd_life_tracker.infrastructure.db.repositories.import_ import ImportRepository
    import sqlmodel.ext.asyncio.session

    args_namespace = _parse_sys_args()
    cache_dir_path = typing.cast(typing.Optional[os.PathLike], args_namespace.cache_dir)

    settings = Settings()  # pyright: ignore[reportCallIssue]

    async with sqlmodel.ext.asyncio.session.AsyncSession(
        create_engine(settings),
        expire_on_commit=False,
    ) as session:
        await run(
            cache=redis.asyncio.Redis(
                host=settings.redis_host,
                port=settings.redis_port,
                username=settings.redis_username,
                password=settings.redis_password,
                db=settings.redis_name,
            ),
            alias_repository=AliasRepository(session),
            import_repository=ImportRepository(session),
            cache_dir_path=cache_dir_path,
        )


if __name__ == "__main__":
    import sys

    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(_main())
