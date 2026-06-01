"""Handlers do worker de email.

Cada handler reage a um evento, resolve o destinatario (consultando o banco a
partir dos ids do payload), envia o email via `EmailNotifier` e registra a
auditoria em `emails_enviados`. Nenhum handler faz commit — quem fecha a
transacao e o consumer, para que envio + auditoria virem uma unidade.
"""
import logging
from typing import Any

from sqlalchemy.orm import Session

from demandas.infrastructure.database import repository as demandas_repository
from emails.infrastructure.database import repository as emails_repository
from emails.infrastructure.database.models import EmailEnviado
from notifier.interface import EmailNotifier
from usuarios.infrastructure.database import repository as usuarios_repository

logger = logging.getLogger(__name__)


def _registrar(
    db: Session,
    *,
    event_id: str,
    routing_key: str,
    destinatario: str,
    assunto: str,
) -> None:
    emails_repository.save(
        db,
        EmailEnviado(
            event_id=event_id,
            routing_key=routing_key,
            destinatario=destinatario,
            assunto=assunto,
            status="ENVIADO",
        ),
    )


def notificar_candidatura_criada(
    db: Session,
    payload: dict[str, Any],
    event_id: str,
    notifier: EmailNotifier,
) -> None:
    """Avisa o CLIENTE dono da demanda que um prestador se candidatou."""
    demanda_id = payload.get("demanda_id")
    prestador_id = payload.get("prestador_id")
    if demanda_id is None or prestador_id is None:
        logger.warning(
            "[email] candidatura.criada sem demanda_id/prestador_id — ignorando"
        )
        return

    demanda = demandas_repository.get_by_id(db, demanda_id)
    if not demanda:
        logger.warning("[email] demanda %s nao encontrada", demanda_id)
        return

    cliente = usuarios_repository.get_by_id(db, demanda.cliente_id)
    if not cliente or not cliente.email:
        logger.warning(
            "[email] cliente %s sem email — ignorando", demanda.cliente_id
        )
        return

    prestador = usuarios_repository.get_by_id(db, prestador_id)
    nome_prestador = prestador.nome if prestador else "Um prestador"

    assunto = f"Nova candidatura na sua demanda: {demanda.titulo}"
    corpo = (
        f"Ola, {cliente.nome}!\n\n"
        f"{nome_prestador} se candidatou a sua demanda "
        f'"{demanda.titulo}".\n\n'
        "Acesse o FieldFlow para revisar a candidatura e decidir.\n\n"
        "-- Equipe FieldFlow"
    )
    notifier.send(cliente.email, assunto, corpo)
    _registrar(
        db,
        event_id=event_id,
        routing_key="candidatura.criada",
        destinatario=cliente.email,
        assunto=assunto,
    )
    logger.info(
        "[email] candidatura.criada notificada ao cliente=%s", cliente.email
    )


def notificar_candidatura_aceita(
    db: Session,
    payload: dict[str, Any],
    event_id: str,
    notifier: EmailNotifier,
) -> None:
    """Avisa o PRESTADOR que sua candidatura foi aceita pelo cliente."""
    demanda_id = payload.get("demanda_id")
    prestador_id = payload.get("prestador_id")
    if prestador_id is None:
        logger.warning("[email] candidatura.aceita sem prestador_id — ignorando")
        return

    prestador = usuarios_repository.get_by_id(db, prestador_id)
    if not prestador or not prestador.email:
        logger.warning(
            "[email] prestador %s sem email — ignorando", prestador_id
        )
        return

    demanda = demandas_repository.get_by_id(db, demanda_id) if demanda_id else None
    titulo = demanda.titulo if demanda else "a demanda"

    assunto = "Sua candidatura foi aceita!"
    corpo = (
        f"Parabens, {prestador.nome}!\n\n"
        f'Sua candidatura para "{titulo}" foi aceita pelo cliente.\n\n'
        "Acesse o FieldFlow para combinar os proximos passos da execucao.\n\n"
        "-- Equipe FieldFlow"
    )
    notifier.send(prestador.email, assunto, corpo)
    _registrar(
        db,
        event_id=event_id,
        routing_key="candidatura.aceita",
        destinatario=prestador.email,
        assunto=assunto,
    )
    logger.info(
        "[email] candidatura.aceita notificada ao prestador=%s",
        prestador.email,
    )
