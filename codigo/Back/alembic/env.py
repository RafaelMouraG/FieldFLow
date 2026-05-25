"""Alembic environment.

A URL do banco vem da mesma fonte da aplicacao (core.config.settings), entao
ambos consomem DATABASE_URL/.env de forma consistente.

Os modulos de modelos sao importados para popular Base.metadata, permitindo
autogenerate em revisoes futuras.
"""
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

from core.config import settings
from core.database import Base

# Side-effect imports: registram cada Table no Base.metadata
import candidaturas.infrastructure.database.models  # noqa: F401
import demandas.infrastructure.database.models  # noqa: F401
import notificacoes.infrastructure.database.models  # noqa: F401
import prestadores.infrastructure.database.models  # noqa: F401
import usuarios.infrastructure.database.models  # noqa: F401

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

config.set_main_option("sqlalchemy.url", settings.database_url)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    context.configure(
        url=config.get_main_option("sqlalchemy.url"),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
