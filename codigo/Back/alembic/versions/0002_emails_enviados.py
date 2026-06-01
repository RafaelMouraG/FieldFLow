"""tabela emails_enviados (auditoria + idempotencia do worker de email)

A baseline (0001) usa Base.metadata.create_all, entao num banco NOVO a tabela
emails_enviados ja nasce na 0001 (o modelo esta registrado no metadata). Num
banco que ja rodou a 0001 ANTES deste modelo existir, a tabela ainda nao existe
e precisa ser criada aqui. Por isso o create e guardado por um inspector: a
revisao fica idempotente nos dois cenarios.

Revision ID: 0002_emails_enviados
Revises: 0001_baseline
Create Date: 2026-06-01
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0002_emails_enviados"
down_revision: Union[str, None] = "0001_baseline"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

TABLE_NAME = "emails_enviados"


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if TABLE_NAME in inspector.get_table_names():
        return

    op.create_table(
        TABLE_NAME,
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("event_id", sa.String(), nullable=False),
        sa.Column("routing_key", sa.String(), nullable=False),
        sa.Column("destinatario", sa.String(), nullable=False),
        sa.Column("assunto", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("enviado_em", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_emails_enviados_id", TABLE_NAME, ["id"]
    )
    op.create_index(
        "ix_emails_enviados_event_id", TABLE_NAME, ["event_id"], unique=True
    )
    op.create_index(
        "ix_emails_enviados_routing_key", TABLE_NAME, ["routing_key"]
    )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if TABLE_NAME not in inspector.get_table_names():
        return
    op.drop_index("ix_emails_enviados_routing_key", table_name=TABLE_NAME)
    op.drop_index("ix_emails_enviados_event_id", table_name=TABLE_NAME)
    op.drop_index("ix_emails_enviados_id", table_name=TABLE_NAME)
    op.drop_table(TABLE_NAME)
