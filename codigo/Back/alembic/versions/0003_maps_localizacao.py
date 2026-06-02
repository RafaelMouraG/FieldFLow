"""coordenadas do local da tarefa (demandas) e endereco da fazenda (usuarios)

Adiciona os campos de geolocalizacao usados pela feature de Maps:
- demandas: origem_lat/lng, destino_lat/lng (ponto exato do talhao);
- usuarios: endereco + endereco_lat/lng (endereco cadastral de clientes CNPJ).

Cada coluna e criada sob um guard de inspector, deixando a revisao idempotente
tanto num banco ja populado quanto num criado do zero pela baseline.

Revision ID: 0003_maps_localizacao
Revises: 0002_emails_enviados
Create Date: 2026-06-02
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0003_maps_localizacao"
down_revision: Union[str, None] = "0002_emails_enviados"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# (tabela, coluna, tipo)
_COLUNAS: list[tuple[str, str, sa.types.TypeEngine]] = [
    ("demandas", "origem_lat", sa.Float()),
    ("demandas", "origem_lng", sa.Float()),
    ("demandas", "destino_lat", sa.Float()),
    ("demandas", "destino_lng", sa.Float()),
    ("usuarios", "endereco", sa.String()),
    ("usuarios", "endereco_lat", sa.Float()),
    ("usuarios", "endereco_lng", sa.Float()),
]


def _colunas_existentes(inspector, tabela: str) -> set[str]:
    return {c["name"] for c in inspector.get_columns(tabela)}


def upgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    for tabela, coluna, tipo in _COLUNAS:
        if coluna not in _colunas_existentes(inspector, tabela):
            op.add_column(tabela, sa.Column(coluna, tipo, nullable=True))


def downgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    for tabela, coluna, _ in reversed(_COLUNAS):
        if coluna in _colunas_existentes(inspector, tabela):
            op.drop_column(tabela, coluna)
