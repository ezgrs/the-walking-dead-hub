import typing
import sqlmodel
import sqlalchemy.orm
import sqlalchemy.sql.ddl


class SQLModelColumn[T: sqlmodel.SQLModel, R]:
    table: sqlmodel.Table
    column: sqlmodel.Column[R]

    def __init__(self, tbl: type[T], accessor: typing.Callable[[T], R]) -> None:
        self.table = tbl.__table__  # pyright: ignore[reportAttributeAccessIssue]
        attr = sqlmodel.col(accessor(typing.cast(T, tbl)))
        if not isinstance(attr, sqlalchemy.orm.InstrumentedAttribute):
            raise TypeError(
                f"{attr} is not a {sqlalchemy.orm.InstrumentedAttribute}"
            )
        self.column = self.table.c[attr.name]


class TempTableQuery[T: sqlmodel.SQLModel]:
    original_table: sqlmodel.Table
    columns: list[SQLModelColumn[T, typing.Any]]

    def __init__(self, cols: list[SQLModelColumn[T, typing.Any]]) -> None:
        tables = {col.table for col in cols}
        if len(tables) > 1:
            raise ValueError(
                f"expected all columns from the same table, got {tables=}"
            )
        (self.original_table,) = iter(tables)
        self.columns = cols

    @property
    def _table_name(self) -> str:
        return f"tmp_{self.original_table.name}"

    def create_statement(
        self,
    ) -> tuple[sqlmodel.Table, str]:
        columns: list[sqlmodel.Column[typing.Any]] = []
        for col in self.columns:
            new_col = col.column.copy()
            new_col.index = False
            new_col.foreign_keys.clear()
            columns.append(new_col)

        tmp_table = sqlmodel.Table(
            self._table_name,
            sqlmodel.MetaData(),
            *columns,
            prefixes=["TEMP"],
        )

        statement = str(
            sqlalchemy.sql.ddl.CreateTable(tmp_table).compile(
                compile_kwargs={"literal_binds": True}
            )
        )
        statement = statement.removesuffix("\n\n")
        return tmp_table, f"{statement} ON COMMIT DROP;\n\n"
