import sqlmodel


class AppearanceFormModel(sqlmodel.SQLModel, table=True):
    __tablename__ = "appearanceforms"  # pyright: ignore[reportAssignmentType]

    id: int | None = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "id",
            sqlmodel.INTEGER,
            primary_key=True,
            autoincrement=True,
        )
    )
    appearance_id: int = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "appearanceid",
            sqlmodel.ForeignKey("appearances.id"),
            nullable=False,
        )
    )
    type_id: int = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "appearanceformtypeid",
            sqlmodel.ForeignKey("appearanceformtypes.id"),
            nullable=False,
        )
    )
