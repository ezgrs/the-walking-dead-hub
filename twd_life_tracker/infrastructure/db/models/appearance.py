import sqlmodel


class AppearanceModel(sqlmodel.SQLModel, table=True):
    __tablename__ = "appearances"  # pyright: ignore[reportAssignmentType]

    id: int | None = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "id",
            sqlmodel.INTEGER,
            primary_key=True,
            autoincrement=True,
        )
    )
    episode_id: int = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "episodeid",
            sqlmodel.ForeignKey("episodes.id"),
            nullable=False,
        )
    )
    entity_id: int = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "entityid",
            sqlmodel.ForeignKey("entities.id"),
            nullable=False,
        )
    )
    type_id: int = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "appearancetypeid",
            sqlmodel.ForeignKey("appearancetypes.id"),
            nullable=False,
        )
    )
