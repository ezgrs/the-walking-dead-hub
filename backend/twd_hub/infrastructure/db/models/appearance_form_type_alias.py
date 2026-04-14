import sqlmodel


class AppearanceFormTypeAliasModel(sqlmodel.SQLModel, table=True):
    __tablename__ = "appearanceformtypealiases"  # pyright: ignore[reportAssignmentType]

    id: int | None = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "id",
            sqlmodel.INTEGER,
            primary_key=True,
            autoincrement=True,
        )
    )
    ref_id: int = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "refid",
            sqlmodel.ForeignKey("appearanceformtypes.id"),
            nullable=False,
        )
    )
    label: str = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "label",
            sqlmodel.VARCHAR(127),
            nullable=False,
        )
    )
