"""initialize appearance form types enum

Revision ID: 02fbf71c7055
Revises: 672cb8549110
Create Date: 2026-04-11 15:45:46.062678

"""
from typing import Sequence, Union
import typing

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '02fbf71c7055'
down_revision: Union[str, Sequence[str], None] = '672cb8549110'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


DATA: typing.Final[typing.Mapping[str, list[str]]] = {
    "alive": ["Alive"],
    "corpse": ["Corpse"],
    "zombified": ["Zombified"],
    "voiceOnly": ["Voice Only", "Voice"],
    "physically": ["Physically"],
    "videoTape": ["Video Tape"],
    "flashback": ["Flashback"],
    "photograph": ["Photograph"],
    "hallucination": ["Hallucination"],
    "dream": ["Dream"],
    "ultrasound": ["Ultrasound"],
}


appearanceformtypes_table = sa.table(
    "appearanceformtypes",
    sa.column("id", sa.Integer),
    sa.column("name", sa.String),
)
appearanceformtypealiases_table = sa.table(
    "appearanceformtypealiases",
    sa.column("id", sa.Integer),
    sa.column("refid", sa.Integer),
    sa.column("label", sa.String),
)


def upgrade() -> None:
    """Upgrade schema."""
    conn = op.get_bind()
    result = conn.execute(
        sa
        .insert(appearanceformtypes_table)
        .returning(appearanceformtypes_table.c.id, appearanceformtypes_table.c.name),
        [{"name": key} for key in DATA.keys()],
    )
    ids_mapping = {key: id for id, key in result.fetchall()}

    op.bulk_insert(
        appearanceformtypealiases_table,
        [
            {
                "refid": ids_mapping[key],
                "label": label,
            } 
            for key, labels in DATA.items()
            for label in labels
        ],
    )


def downgrade() -> None:
    """Downgrade schema."""
    conn = op.get_bind()

    # Fetch IDs from parent table
    result = conn.execute(
        sa.text((
            "SELECT id "
            f"FROM {appearanceformtypes_table.name} "
            "WHERE name = ANY(:names)"
        )),
        {"names": list(DATA.keys())},
    )
    ids = [row[0] for row in result.fetchall()]

    # Delete children rows
    conn.execute(
        sa.text((
            f"DELETE FROM {appearanceformtypealiases_table.name} "
            "WHERE refid = ANY(:ids)"
        )),
        {"ids": ids},
    )

    # Delete parent rows
    conn.execute(
        sa.text((
            f"DELETE FROM {appearanceformtypes_table.name} "
            "WHERE id = ANY(:ids)"
        )),
        {"ids": ids},
    )

