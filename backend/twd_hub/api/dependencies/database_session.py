import typing

import fastapi
import sqlmodel.ext.asyncio.session

import twd_hub.api.dependencies.database_engine


async def evaluate(
    engine: twd_hub.api.dependencies.database_engine.Dependency,
) -> typing.AsyncIterator[sqlmodel.ext.asyncio.session.AsyncSession]:
    async with sqlmodel.ext.asyncio.session.AsyncSession(
        engine,
        expire_on_commit=False,
    ) as session:
        yield session


Dependency = typing.Annotated[
    sqlmodel.ext.asyncio.session.AsyncSession,
    fastapi.Depends(evaluate),
]
