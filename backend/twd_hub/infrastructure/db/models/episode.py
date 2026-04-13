import sqlmodel


class EpisodeModel(sqlmodel.SQLModel, table=True):
    __tablename__ = "episodes"  # pyright: ignore[reportAssignmentType]

    id: int | None = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "id",
            sqlmodel.INTEGER,
            primary_key=True,
            autoincrement=True,
        )
    )
    name: str = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "name",
            sqlmodel.VARCHAR(127),
            nullable=False,
        )
    )
    wiki_href: str = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "wikihref",
            sqlmodel.VARCHAR(127),
            nullable=False,
        )
    )
    season_number: int = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "season",
            sqlmodel.SMALLINT,
            nullable=False,
        )
    )
    episode_number: int = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "number",
            sqlmodel.SMALLINT,
            nullable=False,
        )
    )
