import logging
from typing import Any

from sqlalchemy.orm import Session

from candidaturas.application.use_cases import rejeitar_outras_candidaturas
from mom.interface import EventPublisher
from notificacoes.infrastructure.database import repository as notif_repository
from notificacoes.infrastructure.database.models import Notificacao
from prestadores.application.use_cases import (
    PerfilNaoEncontradoError,
    aprovar_perfil,
    reprovar_perfil,
)
from prestadores.infrastructure.database import (
    repository as prestadores_repository,
)

logger = logging.getLogger(__name__)

MIN_ANOS_EXPERIENCIA = 1
MIN_CERTIFICACOES = 1


def persist_event(
    db: Session,
    routing_key: str,
    payload: dict[str, Any],
    event_id: str,
) -> Notificacao:
    """Grava qualquer evento que chega na fila como Notificacao (auditoria/log).

    A unique constraint em `event_id` garante idempotencia: redelivery do
    broker nao gera linha duplicada (o consumer ja faz a checagem antes, esta
    e a segunda barreira para race conditions).
    """
    notificacao = Notificacao(
        event_id=event_id,
        event_type=routing_key.split(".")[0],
        routing_key=routing_key,
        payload=payload,
    )
    saved = notif_repository.save(db, notificacao)
    logger.info(
        "[worker] gravou notificacao id=%s event_id=%s routing_key=%s",
        saved.id,
        event_id,
        routing_key,
    )
    return saved


def validar_perfil_prestador(
    db: Session, payload: dict[str, Any], publisher: EventPublisher
) -> None:
    """Regra simples: aprova se anos_experiencia >= 1 E certificacoes >= 1."""
    usuario_id = payload.get("usuario_id")
    if usuario_id is None:
        logger.warning("[worker] payload sem usuario_id, ignorando")
        return

    perfil = prestadores_repository.get_by_usuario_id(db, usuario_id)
    if not perfil:
        logger.warning("[worker] perfil %s nao encontrado", usuario_id)
        return

    anos = perfil.anos_experiencia or 0
    qtd_certs = len(perfil.certificacoes or [])

    try:
        if anos >= MIN_ANOS_EXPERIENCIA and qtd_certs >= MIN_CERTIFICACOES:
            aprovar_perfil(db, usuario_id, publisher)
            logger.info("[worker] perfil usuario=%s APROVADO", usuario_id)
        else:
            motivo = (
                f"Perfil insuficiente: anos_experiencia={anos} "
                f"(min {MIN_ANOS_EXPERIENCIA}), certificacoes={qtd_certs} "
                f"(min {MIN_CERTIFICACOES})"
            )
            reprovar_perfil(db, usuario_id, motivo, publisher)
            logger.info(
                "[worker] perfil usuario=%s REPROVADO: %s", usuario_id, motivo
            )
    except PerfilNaoEncontradoError:
        logger.warning(
            "[worker] perfil sumiu durante a validacao usuario=%s", usuario_id
        )


def rejeitar_concorrentes(
    db: Session, payload: dict[str, Any], publisher: EventPublisher
) -> None:
    """Quando uma candidatura é aceita, rejeita todas as outras PENDENTES."""
    demanda_id = payload.get("demanda_id")
    aceita_id = payload.get("id")
    if demanda_id is None or aceita_id is None:
        logger.warning(
            "[worker] candidatura.aceita sem demanda_id/id, ignorando"
        )
        return
    rejeitadas = rejeitar_outras_candidaturas(
        db, demanda_id, aceita_id, publisher
    )
    logger.info(
        "[worker] rejeitou %s candidatura(s) concorrente(s) da demanda %s",
        len(rejeitadas),
        demanda_id,
    )
