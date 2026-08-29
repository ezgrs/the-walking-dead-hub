import contextlib
import types
import typing
import inspect
import fastapi
import fastapi.concurrency
import fastapi.dependencies.utils
import starlette.requests

type LifespanDependency[T] = typing.Callable[
    ..., typing.AsyncContextManager[T] | typing.ContextManager[T]
]


class LifespanDependencyError(BaseException): ...


class _Dependency[**P, T](typing.Protocol):
    __module__: str
    __name__: str

    def __call__(self, *args: P.args, **kwargs: P.kwargs) -> T: ...


class GlobalDependencyFactory[**P, T]:
    _dependency: _Dependency[P, T]

    def __init__(self, dependency: _Dependency[P, T]) -> None:
        self._dependency = dependency

    @property
    def __function__(self) -> _Dependency[P, T]:
        return self._dependency  # pyright: ignore[reportReturnType]

    @property
    def key(self) -> str:
        return f"{self._dependency.__module__}.{self._dependency.__name__}"

    def __call__(
        self,
        connection: starlette.requests.HTTPConnection,
    ) -> typing.Any:
        return getattr(connection.state, self.key)


async def _run_dependency[R](
    exit_stack: contextlib.AsyncExitStack,
    solved_dependency: typing.AsyncContextManager[R] | typing.ContextManager[R],
) -> R:
    return await exit_stack.enter_async_context(
        solved_dependency
        if isinstance(solved_dependency, typing.AsyncContextManager)
        else fastapi.concurrency.contextmanager_in_threadpool(solved_dependency)
    )


class Lifespan:
    def __init__(self) -> None:
        self.dependencies: dict[str, LifespanDependency] = {}

    @contextlib.asynccontextmanager
    async def __call__(
        self,
        _: fastapi.FastAPI,
    ) -> typing.AsyncGenerator[typing.Mapping[str, typing.Any]]:
        state: dict[str, typing.Any] = {}

        async with contextlib.AsyncExitStack() as exit_stack:
            for name, dependency in self.dependencies.items():
                dependant = fastapi.dependencies.utils.get_dependant(
                    path="",
                    call=dependency,
                )
                initial_state_request = fastapi.Request(
                    scope={
                        "type": "http",
                        "query_string": "",
                        "headers": "",
                        "state": state,
                    }
                )

                solved_dependency = (
                    await fastapi.dependencies.utils.solve_dependencies(
                        request=initial_state_request,
                        dependant=dependant,
                        async_exit_stack=exit_stack,
                        embed_body_fields=True,
                    )
                )

                if solved_dependency.background_tasks is not None:
                    raise LifespanDependencyError(
                        "BackgroundTasks are unavailable during startup",
                    )

                if len(solved_dependency.errors) > 0:
                    raise LifespanDependencyError(solved_dependency.errors)

                state[name] = await _run_dependency(
                    exit_stack, dependency(**solved_dependency.values)
                )

            yield state

    def register[**P, T](
        self,
        dependable: GlobalDependencyFactory[P, T],
    ) -> None:
        dependency = dependable.__function__

        context_manager: LifespanDependency[T]
        if inspect.isasyncgenfunction(dependency):
            context_manager = contextlib.asynccontextmanager(dependency)
        elif inspect.isgeneratorfunction(dependency):
            context_manager = contextlib.contextmanager(dependency)
        else:
            raise TypeError(f"{dependable.key} is not a context manager")

        self.dependencies[dependable.key] = context_manager
