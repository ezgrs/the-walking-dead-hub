"""initialize appearance types enum

Revision ID: 672cb8549110
Revises: bba8f2c660e1
Create Date: 2026-04-11 14:57:03.516614

"""
from typing import Sequence, Union
import typing

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '672cb8549110'
down_revision: Union[str, Sequence[str], None] = 'bba8f2c660e1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


DATA: typing.Final[typing.Mapping[str, str]] = {
    "first": "First appearance of",
    "only": "Only appearance of",
    "last": "Last appearance of",
}


appearancetypes_table = sa.table(
    "appearancetypes",
    sa.column("id", sa.Integer),
    sa.column("name", sa.String),
)
appearancetypealiases_table = sa.table(
    "appearancetypealiases",
    sa.column("id", sa.Integer),
    sa.column("refid", sa.Integer),
    sa.column("label", sa.String),
)

def upgrade() -> None:
    """Upgrade schema."""

    conn = op.get_bind()
    result = conn.execute(
        sa
        .insert(appearancetypes_table)
        .returning(appearancetypes_table.c.id, appearancetypes_table.c.name),
        [{"name": key} for key in DATA.keys()],
    )
    ids_mapping = {key: id for id, key in result.fetchall()}

    op.bulk_insert(
        appearancetypealiases_table,
        [
            {
                "refid": ids_mapping[key],
                "label": label,
            } for key, label in DATA.items()
        ],
    )
    



def downgrade() -> None:
    """Downgrade schema."""
    conn = op.get_bind()

    # Fetch IDs from parent table
    result = conn.execute(
        sa.text((
            "SELECT id "
            f"FROM {appearancetypes_table.name} "
            "WHERE name = ANY(:names)"
        )),
        {"names": list(DATA.keys())},
    )
    ids = [row[0] for row in result.fetchall()]

    # Delete children rows
    conn.execute(
        sa.text((
            f"DELETE FROM {appearancetypealiases_table.name} "
            "WHERE refid = ANY(:ids)"
        )),
        {"ids": ids},
    )

    # Delete parent rows
    conn.execute(
        sa.text((
            f"DELETE FROM {appearancetypes_table.name} "
            "WHERE id = ANY(:ids)"
        )),
        {"ids": ids},
    )
