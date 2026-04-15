import sqlmodel
import typing

if typing.TYPE_CHECKING:
    from twd_hub.infrastructure.db.models.appearance import AppearanceModel


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
            sqlmodel.ForeignKey("appearances.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        )
    )
    type_id: int = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "appearanceformtypeid",
            sqlmodel.ForeignKey("appearanceformtypes.id"),
            nullable=False,
        )
    )

    appearance: "AppearanceModel" = sqlmodel.Relationship(back_populates="forms")
