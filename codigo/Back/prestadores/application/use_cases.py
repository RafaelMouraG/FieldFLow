from datetime import datetime, timezone

from sqlalchemy.orm import Session

from mom.interface import EventPublisher
from prestadores.domain.entities import StatusPerfil
from prestadores.infrastructure.database import repository
from prestadores.infrastructure.database.models import PerfilPrestador
from prestadores.presentation.schemas import PerfilSubmit


class PerfilNaoEncontradoError(Exception):
    pass


def _payload(perfil: PerfilPrestador) -> dict:
    return {
        "usuario_id": perfil.usuario_id,
        "status": perfil.status.value,
        "anos_experiencia": perfil.anos_experiencia,
        "especialidades": list(perfil.especialidades or []),
        "qtd_certificacoes": len(perfil.certificacoes or []),
    }


def criar_perfil_pendente(db: Session, usuario_id: int) -> PerfilPrestador:
    perfil = PerfilPrestador(
        usuario_id=usuario_id,
        status=StatusPerfil.INCOMPLETO,
        especialidades=[],
        certificacoes=[],
        regioes_atuacao=[],
        equipamentos_proprios=[],
    )
    saved = repository.save(db, perfil)
    db.commit()
    db.refresh(saved)
    return saved


def get_perfil(db: Session, usuario_id: int) -> PerfilPrestador | None:
    return repository.get_by_usuario_id(db, usuario_id)


def enviar_perfil(
    db: Session,
    usuario_id: int,
    payload: PerfilSubmit,
    publisher: EventPublisher,
) -> PerfilPrestador:
    perfil = repository.get_by_usuario_id(db, usuario_id)
    if not perfil:
        perfil = PerfilPrestador(usuario_id=usuario_id)

    for key, value in payload.model_dump().items():
        setattr(perfil, key, value)
    perfil.status = StatusPerfil.EM_ANALISE
    perfil.enviado_em = datetime.now(tz=timezone.utc)
    perfil.motivo_reprovacao = None
    perfil.avaliado_em = None
    saved = repository.save(db, perfil)
    db.commit()
    db.refresh(saved)

    publisher.publish("prestador.perfil.enviado", _payload(saved))
    return saved


def aprovar_perfil(
    db: Session, usuario_id: int, publisher: EventPublisher
) -> PerfilPrestador:
    perfil = repository.get_by_usuario_id(db, usuario_id)
    if not perfil:
        raise PerfilNaoEncontradoError()
    perfil.status = StatusPerfil.APROVADO
    perfil.motivo_reprovacao = None
    perfil.avaliado_em = datetime.now(tz=timezone.utc)
    saved = repository.save(db, perfil)
    db.commit()
    db.refresh(saved)
    publisher.publish("prestador.aprovado", _payload(saved))
    return saved


def reprovar_perfil(
    db: Session, usuario_id: int, motivo: str, publisher: EventPublisher
) -> PerfilPrestador:
    perfil = repository.get_by_usuario_id(db, usuario_id)
    if not perfil:
        raise PerfilNaoEncontradoError()
    perfil.status = StatusPerfil.REPROVADO
    perfil.motivo_reprovacao = motivo
    perfil.avaliado_em = datetime.now(tz=timezone.utc)
    saved = repository.save(db, perfil)
    db.commit()
    db.refresh(saved)
    payload = _payload(saved)
    payload["motivo"] = motivo
    publisher.publish("prestador.reprovado", payload)
    return saved
