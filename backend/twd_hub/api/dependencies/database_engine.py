import subprocess
import typing

import fastapi
import sqlalchemy
import sqlalchemy.pool
import sqlalchemy.ext.asyncio
import alembic.config

from twd_hub.api.fastapi_lifespan_dependencies import (
    GlobalDependencyFactory,
)
from twd_hub.api.dependencies.settings import (
    Dependency as SettingsDependency,
)


def create(
    settings: SettingsDependency,
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


@GlobalDependencyFactory
async def evaluate(
    settings: SettingsDependency,
) -> typing.AsyncIterator[sqlalchemy.ext.asyncio.AsyncEngine]:
    cfg = alembic.config.Config("alembic.ini")

    def _run_upgrade(connection: sqlalchemy.Connection) -> None:
        cfg.attributes["connection"] = connection
        # https://github.com/sqlalchemy/alembic/discussions/1483
        result = subprocess.run(
            ["alembic", "upgrade", "head"],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr

    engine = create(settings)
    async with engine.connect() as conn:
        await conn.run_sync(_run_upgrade)

    yield engine


Dependency = typing.Annotated[
    sqlalchemy.ext.asyncio.AsyncEngine,
    fastapi.Depends(evaluate),
]
