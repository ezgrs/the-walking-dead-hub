import typing

import fastapi

from twd_hub.domain.models.settings import Settings
from twd_hub.api.fastapi_lifespan_dependencies import (
    GlobalDependencyFactory,
)


@GlobalDependencyFactory
def evaluate() -> typing.Iterator[Settings]:
    yield Settings()  # pyright: ignore[reportCallIssue]


Dependency = typing.Annotated[Settings, fastapi.Depends(evaluate)]
