"""Segundo consumidor: serviço de notificação por email.

Consome a fila propria `fieldflow.emails`, ligada ao mesmo topic exchange que o
worker de negocio. Os dois consumidores recebem copias do mesmo evento (padrao
Publish-Subscribe / fan-out) e trabalham isolados: uma falha de SMTP manda a
mensagem para `fieldflow.emails.dlq` sem afetar o processamento de negocio.
"""
import json
import logging

from core.config import settings
from core.database import SessionLocal
from emails.infrastructure.database import repository as emails_repository
from notifier.dependencies import get_email_notifier
from worker.amqp import connect_with_retry
from worker.email_handlers import (
    notificar_candidatura_aceita,
    notificar_candidatura_criada,
)

logger = logging.getLogger(__name__)

QUEUE_NAME = "fieldflow.emails"
BINDINGS = ["candidatura.criada", "candidatura.aceita"]
DLX_NAME = "fieldflow.emails.dlx"
DLQ_NAME = "fieldflow.emails.dlq"

_HANDLERS = {
    "candidatura.criada": notificar_candidatura_criada,
    "candidatura.aceita": notificar_candidatura_aceita,
}


def _process(routing_key: str, payload: dict, event_id: str) -> None:
    handler = _HANDLERS.get(routing_key)
    if handler is None:
        logger.info("[email] routing_key %s sem handler — pulando", routing_key)
        return

    db = SessionLocal()
    try:
        if emails_repository.get_by_event_id(db, event_id) is not None:
            logger.info(
                "[email] evento ja notificado event_id=%s — pulando", event_id
            )
            return

        handler(db, payload, event_id, get_email_notifier())
        # Commit ao final: envio do email + registro de auditoria viram uma
        # unica transacao. Se o handler nao gravou (destinatario invalido),
        # o commit simplesmente nao persiste nada.
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def _extract_event_id(properties, payload: dict) -> str | None:
    if properties and properties.message_id:
        return properties.message_id
    return payload.get("event_id")


def _on_message(channel, method, properties, body) -> None:
    routing_key = method.routing_key
    try:
        payload = json.loads(body.decode("utf-8"))
    except json.JSONDecodeError:
        logger.exception("[email] payload invalido — descartando")
        channel.basic_ack(delivery_tag=method.delivery_tag)
        return

    event_id = _extract_event_id(properties, payload)
    if not event_id:
        logger.warning(
            "[email] mensagem sem event_id routing_key=%s — descartando",
            routing_key,
        )
        channel.basic_ack(delivery_tag=method.delivery_tag)
        return

    try:
        _process(routing_key, payload, event_id)
        channel.basic_ack(delivery_tag=method.delivery_tag)
    except Exception:
        logger.exception(
            "[email] falha ao processar %s id=%s — indo pra DLQ",
            routing_key,
            event_id,
        )
        channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)


def _declare_topology(connection, exchange: str):
    channel = connection.channel()
    channel.exchange_declare(
        exchange=exchange, exchange_type="topic", durable=True
    )
    channel.exchange_declare(
        exchange=DLX_NAME, exchange_type="fanout", durable=True
    )
    channel.queue_declare(queue=DLQ_NAME, durable=True)
    channel.queue_bind(queue=DLQ_NAME, exchange=DLX_NAME)
    channel.queue_declare(
        queue=QUEUE_NAME,
        durable=True,
        arguments={"x-dead-letter-exchange": DLX_NAME},
    )
    for pattern in BINDINGS:
        channel.queue_bind(
            queue=QUEUE_NAME, exchange=exchange, routing_key=pattern
        )
    channel.basic_qos(prefetch_count=10)
    return channel


def run() -> None:
    if not settings.rabbitmq_url:
        raise RuntimeError("RABBITMQ_URL nao configurada")

    connection = connect_with_retry()
    exchange = settings.mom_exchange
    channel = _declare_topology(connection, exchange)
    channel.basic_consume(queue=QUEUE_NAME, on_message_callback=_on_message)

    logger.info(
        "[email] consumindo exchange=%s queue=%s bindings=%s dlq=%s",
        exchange,
        QUEUE_NAME,
        BINDINGS,
        DLQ_NAME,
    )
    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        logger.info("[email] interrompido pelo usuario")
    finally:
        connection.close()
