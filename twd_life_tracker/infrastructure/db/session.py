import sqlalchemy.ext.asyncio

from twd_life_tracker.domain.models.settings import Settings


def create_engine(
    settings: Settings,
) -> sqlalchemy.ext.asyncio.AsyncEngine:
    return sqlalchemy.ext.asyncio.create_async_engine(
        sqlalchemy.URL.create(
            settings.database_driver,
            username=settings.database_username,
            password=settings.database_password,
            host=settings.database_host,
            port=settings.database_port,
            database=settings.database_name,
        ),
        poolclass=sqlalchemy.pool.AsyncAdaptedQueuePool,
    )
