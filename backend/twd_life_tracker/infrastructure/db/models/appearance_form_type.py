import sqlmodel


class AppearanceFormTypeModel(sqlmodel.SQLModel, table=True):
    __tablename__ = (
        "appearanceformtypes"  # pyright: ignore[reportAssignmentType]
    )

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
