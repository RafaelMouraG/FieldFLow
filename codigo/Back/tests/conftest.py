"""Configuracao de testes.

Usa SQLite in-memory para nao depender do Postgres. Um FakeEventPublisher
captura eventos publicados pelos use cases, permitindo asserts sobre o MOM
sem subir o RabbitMQ.
"""
from typing import Any

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from auth.security import hash_password
from candidaturas.infrastructure.database import models as _c_models  # noqa: F401
from core.database import Base
from demandas.infrastructure.database import models as _d_models  # noqa: F401
from mom.interface import EventPublisher
from notificacoes.infrastructure.database import models as _n_models  # noqa: F401
from prestadores.domain.entities import StatusPerfil
from prestadores.infrastructure.database import models as _p_models  # noqa: F401
from prestadores.infrastructure.database.models import PerfilPrestador
from usuarios.domain.entities import TipoDocumento, TipoUsuario
from usuarios.infrastructure.database import models as _u_models  # noqa: F401
from usuarios.infrastructure.database.models import Usuario


class FakeEventPublisher(EventPublisher):
    def __init__(self) -> None:
        self.events: list[tuple[str, dict[str, Any], str]] = []

    def _do_publish(
        self, event_type: str, payload: dict[str, Any], event_id: str
    ) -> None:
        self.events.append((event_type, payload, event_id))

    def routing_keys(self) -> list[str]:
        return [e[0] for e in self.events]


@pytest.fixture()
def db():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    SessionLocal = sessionmaker(bind=engine, autoflush=False)
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def publisher() -> FakeEventPublisher:
    return FakeEventPublisher()


def _criar_usuario(
    db, *, nome: str, email: str, tipo: TipoUsuario, documento: str
) -> Usuario:
    usuario = Usuario(
        nome=nome,
        email=email,
        documento=documento,
        tipo_documento=TipoDocumento.CPF,
        tipo=tipo,
        senha_hash=hash_password("senha123"),
        ativo=True,
    )
    db.add(usuario)
    db.commit()
    db.refresh(usuario)
    return usuario


@pytest.fixture()
def cliente(db):
    return _criar_usuario(
        db,
        nome="Cliente Teste",
        email="cliente@teste.com",
        tipo=TipoUsuario.CLIENTE,
        documento="11111111111",
    )


@pytest.fixture()
def prestador_aprovado(db):
    usuario = _criar_usuario(
        db,
        nome="Prestador OK",
        email="prestador1@teste.com",
        tipo=TipoUsuario.PRESTADOR,
        documento="22222222222",
    )
    perfil = PerfilPrestador(
        usuario_id=usuario.id,
        status=StatusPerfil.APROVADO,
        anos_experiencia=3,
        especialidades=["PULVERIZACAO"],
        certificacoes=["NR-31"],
    )
    db.add(perfil)
    db.commit()
    return usuario


@pytest.fixture()
def outro_prestador_aprovado(db):
    usuario = _criar_usuario(
        db,
        nome="Outro Prestador",
        email="prestador2@teste.com",
        tipo=TipoUsuario.PRESTADOR,
        documento="33333333333",
    )
    perfil = PerfilPrestador(
        usuario_id=usuario.id,
        status=StatusPerfil.APROVADO,
        anos_experiencia=2,
        especialidades=["PLANTIO"],
        certificacoes=["NR-31"],
    )
    db.add(perfil)
    db.commit()
    return usuario
