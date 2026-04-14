import argparse
import asyncio
import os
import pathlib
import typing
import aiopath
import redis.asyncio
import sqlmodel.ext.asyncio.session

from twd_hub.application.services.database_initializer import (
    DatabaseInitializer,
)
from twd_hub.application.services.episode_page_scraper import (
    DefaultEpisodePageScraper,
    EpisodePageScraper,
)
from twd_hub.domain.interfaces.alias_repository import AliasRepository
from twd_hub.domain.models.settings import Settings
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
from twd_hub.infrastructure.decorators.episode_page_scraper.read_through_cache import (
    ReadThroughCacheEpisodePageScraper,
)
from twd_hub.infrastructure.decorators.episode_page_scraper.write_through_cache import (
    WriteThroughCacheEpisodePageScraper,
)
from twd_hub.infrastructure.decorators.html_loader.read_through_cache import (
    ReadThroughCacheHtmlLoader,
)
from twd_hub.infrastructure.decorators.html_loader.write_through_cache import (
    WriteThroughCacheHtmlLoader,
)
from twd_hub.infrastructure.services.cache_store.aiopath_impl import (
    AiopathCacheStore,
)
from twd_hub.infrastructure.services.html_loader.playwright_impl import (
    PlaywrightHtmlLoader,
)
from twd_hub.infrastructure.services.html_parser.bs4_impl import Bs4HtmlParser


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

    html_loader = PlaywrightHtmlLoader()
    if cache_dir_path is not None:
        html_cache = AiopathCacheStore(base_dir=aiopath.Path(cache_dir_path))
        html_loader = WriteThroughCacheHtmlLoader(html_loader, cache=html_cache)
        html_loader = ReadThroughCacheHtmlLoader(html_loader, cache=html_cache)

    async with sqlmodel.ext.asyncio.session.AsyncSession(
        create_engine(settings),
        expire_on_commit=False,
    ) as session:
        alias_repository = AliasRepository(session)
        episode_repository = EpisodeRepository(session)
        entity_repository = EntityRepository(session)
        appearance_repository = AppearanceRepository(session)
        appearance_form_repository = AppearanceFormRepository(session)

        html_parser = Bs4HtmlParser(alias_repository=alias_repository)

        episode_page_scraper = DefaultEpisodePageScraper(
            html_loader=html_loader,
            html_parser=html_parser,
        )
        episode_page_scraper = WriteThroughCacheEpisodePageScraper(
            episode_page_scraper,
        )
        episode_page_scraper = ReadThroughCacheEpisodePageScraper(
            episode_page_scraper,
        )

        db_initializer = DatabaseInitializer(
            episode_page_scraper=episode_page_scraper,
            episode_repository=episode_repository,
            entity_repository=entity_repository,
            appearance_repository=appearance_repository,
            appearance_form_repository=appearance_form_repository,
        )
        async with html_loader:
            await db_initializer.run(
                initial_page_href="/wiki/Days_Gone_Bye_(TV_Series)",
                load_until=(7, 16),
            )

        await session.commit()


if __name__ == "__main__":
    import sys

    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())
