import argparse
import asyncio
import os
import pathlib
import typing
import aiopath
import redis.asyncio
import sqlmodel.ext.asyncio.session

from twd_hub.domain.interfaces.alias_repository import AliasRepository
from twd_hub.domain.models.settings import Settings
from twd_hub.domain.services.database_initializer.server import (
    DatabaseInitializer,
)
from twd_hub.domain.services.episode_page_loader import EpisodeLoader
from twd_hub.domain.services.page_loader import PageLoader
from twd_hub.domain.services.tag_parser import TagParser
from twd_hub.infrastructure.db.repositories.appearance import (
    AppearanceRepository,
)
from twd_hub.infrastructure.db.repositories.appearance_form import (
    AppearanceFormRepository,
)
from twd_hub.infrastructure.db.repositories.entity import EntityRepository
from twd_hub.infrastructure.db.repositories.episode import EpisodeRepository

from twd_hub.infrastructure.db.session import create_engine
from twd_hub.infrastructure.db.repositories.alias import AliasRepository


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


async def main() -> None:
    args_namespace = _parse_sys_args()
    cache_dir_path = typing.cast(
        typing.Optional[os.PathLike], args_namespace.cache_dir
    )

    settings = Settings()  # pyright: ignore[reportCallIssue]

    cache = redis.asyncio.Redis(
        host=settings.redis_host,
        port=settings.redis_port,
        username=settings.redis_username,
        password=settings.redis_password,
        db=settings.redis_name,
    )

    page_loader = PageLoader.from_server()
    if cache_dir_path is not None:
        dpath = aiopath.Path(cache_dir_path)
        page_loader = page_loader.with_write_through_cache(
            dpath
        ).with_read_through_cache(dpath)

    async with sqlmodel.ext.asyncio.session.AsyncSession(
        create_engine(settings),
        expire_on_commit=False,
    ) as session:
        alias_repository = AliasRepository(session)
        episode_repository = EpisodeRepository(session)
        entity_repository = EntityRepository(session)
        appearance_repository = AppearanceRepository(session)
        appearance_form_repository = AppearanceFormRepository(session)

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

        db_initializer = DatabaseInitializer(
            loader=episode_loader,
            episode_repository=episode_repository,
            entity_repository=entity_repository,
            appearance_repository=appearance_repository,
            appearance_form_repository=appearance_form_repository,
        )
        async with page_loader:
            await db_initializer.run()

        await session.commit()


if __name__ == "__main__":
    import sys

    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())
