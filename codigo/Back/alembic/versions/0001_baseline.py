"""baseline schema

Cria todas as tabelas a partir do Base.metadata atual (usuarios, prestadores,
demandas, candidaturas, notificacoes). Migracoes seguintes devem ser geradas
via `alembic revision --autogenerate` e expressar diffs em DDL explicito.

Revision ID: 0001_baseline
Revises:
Create Date: 2026-05-25
"""
from typing import Sequence, Union

from alembic import op

# Side-effect imports: registram cada Table no Base.metadata
import avaliacoes.infrastructure.database.models  # noqa: F401
import candidaturas.infrastructure.database.models  # noqa: F401
import demandas.infrastructure.database.models  # noqa: F401
import notificacoes.infrastructure.database.models  # noqa: F401
import prestadores.infrastructure.database.models  # noqa: F401
import usuarios.infrastructure.database.models  # noqa: F401
from core.database import Base

revision: str = "0001_baseline"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    Base.metadata.create_all(bind=op.get_bind())


def downgrade() -> None:
    Base.metadata.drop_all(bind=op.get_bind())
