import asyncio
import os
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
        page_loader = page_loader.with_read_through_cache(
            dpath
        ).with_write_through_cache(dpath)

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


async def _main() -> None:
    from twd_life_tracker.infrastructure.db.session import create_engine
    from twd_life_tracker.infrastructure.db.repositories.alias import AliasRepository
    from twd_life_tracker.infrastructure.db.repositories.import_ import ImportRepository
    import sqlmodel.ext.asyncio.session

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
            cache_dir_path=settings.cache_dir_path,
        )


if __name__ == "__main__":
    import sys

    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(_main())
