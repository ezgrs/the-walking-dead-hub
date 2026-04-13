import typing

import fastapi

from twd_life_tracker.domain.models.settings import Settings
from twd_life_tracker.api.fastapi_lifespan_dependencies import (
    GlobalDependencyFactory,
)


@GlobalDependencyFactory
def evaluate() -> typing.Iterator[Settings]:
    yield Settings()  # pyright: ignore[reportCallIssue]


Dependency = typing.Annotated[Settings, fastapi.Depends(evaluate)]
