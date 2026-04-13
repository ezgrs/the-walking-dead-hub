import typing


class Upsertable[ModelBase, Model](typing.Protocol):
    async def read_all(self) -> list[Model]: ...
    async def create(self, data: ModelBase) -> Model: ...


class Upsert[ModelBase, Model, Id: object, Key]:
    @staticmethod
    async def of[MB, M, I, K](
        upsertable: Upsertable[MB, M],
        *,
        on_id: typing.Callable[[M], I],
        on_key: typing.Callable[[M], K],
    ) -> "Upsert[MB, M, I, K]":
        return Upsert(
            upsertable=upsertable,
            mapping={
                on_key(model): model for model in await upsertable.read_all()
            },
            on_id=on_id,
        )

    upsertable: Upsertable[ModelBase, Model]
    mapping: dict[Key, Model]
    on_id: typing.Callable[[Model], Id]

    def __init__(
        self,
        *,
        upsertable: Upsertable[ModelBase, Model],
        mapping: dict[Key, Model],
        on_id: typing.Callable[[Model], Id],
    ) -> None:
        self.upsertable = upsertable
        self.mapping = mapping
        self.on_id = on_id

    async def get_or_insert(
        self,
        key: Key,
        *,
        on_insert: typing.Callable[[], ModelBase],
    ) -> tuple[Id, Model]:
        model: Model
        model_base = self.mapping.get(key)
        if model_base is None:
            model_base = on_insert()
            model = await self.upsertable.create(model_base)
            self.mapping[key] = model
        else:
            model = typing.cast(Model, model_base)

        return self.on_id(model), model
