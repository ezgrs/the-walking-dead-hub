import typing
import sqlmodel

if typing.TYPE_CHECKING:
    from twd_hub.infrastructure.db.models.appearance_form import (
        AppearanceFormModel,
    )
    from twd_hub.infrastructure.db.models.episode import EpisodeModel
    from twd_hub.infrastructure.db.models.entity import EntityModel


class AppearanceModel(sqlmodel.SQLModel, table=True):
    __tablename__ = "appearances"  # pyright: ignore[reportAssignmentType]
    __table_args__ = (
        sqlmodel.UniqueConstraint(
            "episodeid",
            "entityid",
        ),
    )

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
            sqlmodel.ForeignKey("episodes.id", ondelete="CASCADE"),
            nullable=False,
        )
    )
    entity_id: int = sqlmodel.Field(
        sa_column=sqlmodel.Column(
            "entityid",
            sqlmodel.ForeignKey("entities.id", ondelete="CASCADE"),
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

    forms: list["AppearanceFormModel"] = sqlmodel.Relationship(
        back_populates="appearance", cascade_delete=True, passive_deletes=True
    )
    episode: "EpisodeModel" = sqlmodel.Relationship(
        back_populates="appearances"
    )
    entity: "EntityModel" = sqlmodel.Relationship(back_populates="appearances")
