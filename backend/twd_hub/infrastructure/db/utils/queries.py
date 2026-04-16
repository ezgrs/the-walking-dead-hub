import typing
import sqlmodel
import sqlmodel.ext.asyncio.session
import sqlalchemy.dialects.postgresql

from twd_hub.infrastructure.db.utils.tables import (
    SQLModelColumn,
    TempTableQuery,
)


class SQLModelColumnUpdateSpec[M: sqlmodel.SQLModel, R, D](typing.NamedTuple):
    col: SQLModelColumn[M, R]
    accessor: typing.Callable[[D], R]


async def update_all[D, M: sqlmodel.SQLModel](
    session: sqlmodel.ext.asyncio.session.AsyncSession,
    table: type[M],
    datum: list[D],
    *,
    index_cols_specs: list[SQLModelColumnUpdateSpec[M, typing.Any, D]],
    update_cols_specs: list[SQLModelColumnUpdateSpec[M, typing.Any, D]],
) -> None:
    cols: list[SQLModelColumn[M, typing.Any]] = [
        spec.col for spec in (*index_cols_specs, *update_cols_specs)
    ]

    query = TempTableQuery(cols)
    tmp_table, create_statement = query.create_statement()

    # Create temporary table
    # CREATE TEMP TABLE tmp_table (...) ON COMMIT DROP;
    await session.execute(sqlmodel.text(create_statement))

    # Populate temporary table
    await session.execute(
        tmp_table.insert(),
        [
            {
                spec.col.column.name: spec.accessor(data)
                for spec in (*index_cols_specs, *update_cols_specs)
            }
            for data in datum
        ],
    )

    # Update Model from temporary table
    # INSERT INTO table
    # SELECT (...) FROM tmp_table
    # ON CONFLICT (index_col)
    # DO UPDATE
    #   SET update_col = excluded.update_col;
    statement = sqlalchemy.dialects.postgresql.insert(table).from_select(
        [tmp_table.c[col.column.name] for col in cols],
        sqlalchemy.select(tmp_table),
    )
    await session.execute(
        statement.on_conflict_do_update(
            index_elements=[spec.col.column for spec in index_cols_specs],
            set_={
                spec.col.column: getattr(
                    statement.excluded, spec.col.column.name
                )
                for spec in update_cols_specs
            },
        )
    )

    # Remove outdated EpisodeModels
    # DELETE FROM episodes
    # WHERE NOT EXISTS (
    #   SELECT 1 FROM tmp_episodes
    #   WHERE tmp_episodes.index_col = episodes.index_col
    # )
    await session.execute(
        sqlmodel.delete(table).where(
            ~sqlmodel.exists(
                sqlmodel.select(1).where(
                    *(
                        tmp_table.c[spec.col.column.name] == spec.col.column
                        for spec in index_cols_specs
                    )
                )
            )
        )
    )
    await session.commit()
