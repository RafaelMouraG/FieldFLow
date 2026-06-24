"""marca d'agua de notificacoes lidas por usuario

Adiciona usuarios.notificacoes_lidas_ate_id: maior id de notificacao ja visto
pelo usuario. O feed (`GET /notificacoes`) marca como lida toda notificacao com
id <= este valor, e `POST /notificacoes/marcar-lidas` avanca a marca.

Coluna criada sob guard de inspector, deixando a revisao idempotente tanto num
banco ja populado quanto num criado do zero pela baseline.

Revision ID: 0005_notificacoes_lidas
Revises: 0004_avaliacoes
Create Date: 2026-06-23
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0005_notificacoes_lidas"
down_revision: Union[str, None] = "0004_avaliacoes"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

TABLE_NAME = "usuarios"
COLUMN_NAME = "notificacoes_lidas_ate_id"


def _colunas_existentes(inspector, tabela: str) -> set[str]:
    return {c["name"] for c in inspector.get_columns(tabela)}


def upgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    if COLUMN_NAME not in _colunas_existentes(inspector, TABLE_NAME):
        op.add_column(
            TABLE_NAME,
            sa.Column(
                COLUMN_NAME,
                sa.Integer(),
                nullable=False,
                server_default="0",
            ),
        )


def downgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    if COLUMN_NAME in _colunas_existentes(inspector, TABLE_NAME):
        op.drop_column(TABLE_NAME, COLUMN_NAME)
