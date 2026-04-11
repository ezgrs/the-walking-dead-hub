import asyncio

import aiopath
import sqlmodel
import sqlmodel.ext.asyncio.session

from twd_life_tracker.domain.services.page_loader import PageLoader
from twd_life_tracker.domain.services.tag_parser import TagParser
from twd_life_tracker.infrastructure.db.repositories.alias import (
    AliasRepository,
)
from twd_life_tracker.infrastructure.db.repositories.import_ import (
    ImportRepository,
)
from twd_life_tracker.infrastructure.db.session import create_engine
from twd_life_tracker.domain.models.settings import Settings


async def main() -> None:
    settings = Settings()  # pyright: ignore[reportCallIssue]

    db_engine = create_engine(settings)
    async with sqlmodel.ext.asyncio.session.AsyncSession(
        db_engine,
        expire_on_commit=False,
    ) as session:
        import_repository = ImportRepository(session)
        alias_repository = AliasRepository(session)

        page_loader = PageLoader.from_server()
        cache_dir_path = settings.cache_dir_path
        if cache_dir_path is not None:
            dpath = aiopath.Path(cache_dir_path)
            page_loader = page_loader.with_read_through_cache(
                dpath
            ).with_write_through_cache(dpath)

        tag_parser = TagParser.episode_page(
            entity_appearance_parser=TagParser.entity_appearance(
                alias_repository=alias_repository,
            ),
        )
        await import_repository.import_data(
            page_loader=page_loader,
            tag_parser=tag_parser,
        )


if __name__ == "__main__":
    import sys
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())
