"""Aplicacao programatica das migracoes Alembic.

Substitui o `Base.metadata.create_all` que era chamado no startup da API e
do worker — agora o schema evolui via revisoes versionadas, sem precisar
de `docker compose down -v` a cada mudanca.

Usa um path absoluto pra `alembic.ini` para nao depender do CWD do processo.
"""
from pathlib import Path

from alembic import command
from alembic.config import Config

from core.config import settings

_BACK_DIR = Path(__file__).resolve().parent.parent
_ALEMBIC_INI = _BACK_DIR / "alembic.ini"


def upgrade_head() -> None:
    cfg = Config(str(_ALEMBIC_INI))
    cfg.set_main_option("script_location", str(_BACK_DIR / "alembic"))
    cfg.set_main_option("sqlalchemy.url", settings.database_url)
    command.upgrade(cfg, "head")
