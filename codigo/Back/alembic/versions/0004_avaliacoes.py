"""tabela avaliacoes (cliente avalia o prestador apos demanda CONCLUIDA)

Idempotente: num banco novo a tabela ja nasce na 0001 (modelo registrado no
Base.metadata via side-effect import); num banco que ja rodou a 0001 antes deste
modelo existir, ela e criada aqui. O guard de inspector cobre os dois casos.

Revision ID: 0004_avaliacoes
Revises: 0003_maps_localizacao
Create Date: 2026-06-02
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0004_avaliacoes"
down_revision: Union[str, None] = "0003_maps_localizacao"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

TABLE_NAME = "avaliacoes"


def upgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    if TABLE_NAME in inspector.get_table_names():
        return

    op.create_table(
        TABLE_NAME,
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "demanda_id",
            sa.Integer(),
            sa.ForeignKey("demandas.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "autor_id",
            sa.Integer(),
            sa.ForeignKey("usuarios.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "prestador_id",
            sa.Integer(),
            sa.ForeignKey("usuarios.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("nota", sa.Integer(), nullable=False),
        sa.Column("comentario", sa.Text(), nullable=True),
        sa.Column("criado_em", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("demanda_id", name="uq_avaliacao_demanda"),
    )
    op.create_index("ix_avaliacoes_id", TABLE_NAME, ["id"])
    op.create_index("ix_avaliacoes_demanda_id", TABLE_NAME, ["demanda_id"])
    op.create_index("ix_avaliacoes_autor_id", TABLE_NAME, ["autor_id"])
    op.create_index(
        "ix_avaliacoes_prestador_id", TABLE_NAME, ["prestador_id"]
    )


def downgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    if TABLE_NAME not in inspector.get_table_names():
        return
    op.drop_index("ix_avaliacoes_prestador_id", table_name=TABLE_NAME)
    op.drop_index("ix_avaliacoes_autor_id", table_name=TABLE_NAME)
    op.drop_index("ix_avaliacoes_demanda_id", table_name=TABLE_NAME)
    op.drop_index("ix_avaliacoes_id", table_name=TABLE_NAME)
    op.drop_table(TABLE_NAME)
