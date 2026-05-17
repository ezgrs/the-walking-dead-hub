import os
import os.path
import tomllib
import http.client

import dotenv
import fastapi
import fastapi.exception_handlers
import fastapi.middleware.cors


import twd_hub.api.fastapi_lifespan_dependencies
import twd_hub.api.dependencies.settings
import twd_hub.api.dependencies.database_engine
import twd_hub.api.routers.entities
import twd_hub.api.routers.seasons


def _find_nearest_pyproject(current_dir: str) -> str:
    pyproject_path = os.path.join(current_dir, "pyproject.toml")
    if os.path.isfile(pyproject_path):
        return pyproject_path

    parent_dir = os.path.dirname(current_dir)
    if parent_dir == current_dir:
        raise RuntimeError("could not find pyproject.toml")
    return _find_nearest_pyproject(parent_dir)


def _read_poetry_version(pyproject_path: str) -> str:
    with open(pyproject_path, "rb") as f:
        data = tomllib.load(f)
    return data["project"]["version"]


def create_app() -> fastapi.FastAPI:
    dotenv.load_dotenv()

    lifespan = twd_hub.api.fastapi_lifespan_dependencies.Lifespan()
    lifespan.register(twd_hub.api.dependencies.settings.evaluate)
    lifespan.register(twd_hub.api.dependencies.database_engine.evaluate)

    app = fastapi.FastAPI(
        title="The Walking Dead Hub API",
        description=(
            "A The Walking Dead character database providing a complete overview of each character's journey."
        ),
        version=_read_poetry_version(_find_nearest_pyproject(os.getcwd())),
        contact={
            "name": "Enzo Santos",
            "url": "https://github.com/ezgrs",
            "email": "ezgrs.dev@gmail.com",
        },
        lifespan=lifespan,
    )
    app.add_middleware(
        fastapi.middleware.cors.CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.exception_handler(fastapi.exceptions.HTTPException)
    async def _(
        request: fastapi.Request,
        exc: fastapi.exceptions.HTTPException,
    ) -> fastapi.Response:
        if exc.status_code in {
            http.client.UNAUTHORIZED,
            http.client.FORBIDDEN,
            http.client.NOT_FOUND,
            http.client.CONFLICT,
        }:
            # "fastapi.exceptions.HTTPException: %d", exc.status_code
            ...
        else:
            # "fastapi.exceptions.HTTPException", exc_info=exc
            ...
        return await fastapi.exception_handlers.http_exception_handler(
            request, exc
        )

    @app.exception_handler(fastapi.exceptions.RequestValidationError)
    async def _(
        request: fastapi.Request,
        exc: fastapi.exceptions.RequestValidationError,
    ) -> fastapi.responses.JSONResponse:
        # "fastapi.exceptions.RequestValidationError", exc_info=exc
        return await fastapi.exception_handlers.request_validation_exception_handler(
            request, exc
        )

    app.include_router(twd_hub.api.routers.entities.router, prefix="/entities")
    app.include_router(twd_hub.api.routers.seasons.router, prefix="/seasons")

    return app
