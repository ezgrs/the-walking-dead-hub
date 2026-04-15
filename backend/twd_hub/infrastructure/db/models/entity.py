import typing
import sqlmodel

if typing.TYPE_CHECKING:
    from twd_hub.infrastructure.db.models.appearance import AppearanceModel


class EntityModel(sqlmodel.SQLModel, table=True):
    __tablename__ = "entities"  # pyright: ignore[reportAssignmentType]

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
            unique=True,
        )
    )

    appearances: list["AppearanceModel"] = sqlmodel.Relationship(
        back_populates="entity", cascade_delete=True, passive_deletes=True
    )
