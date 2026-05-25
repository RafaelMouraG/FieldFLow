import json
import logging
import time

import pika
from pika.exceptions import AMQPConnectionError, ChannelClosedByBroker

from core.config import settings
from core.database import SessionLocal
from mom.dependencies import get_event_publisher
from notificacoes.infrastructure.database import repository as notif_repository
from worker.handlers import (
    persist_event,
    rejeitar_concorrentes,
    validar_perfil_prestador,
)

logger = logging.getLogger(__name__)

QUEUE_NAME = "fieldflow.notificacoes"
BINDINGS = ["demanda.#", "usuario.#", "prestador.#", "candidatura.#"]
DLX_NAME = "fieldflow.events.dlx"
DLQ_NAME = "fieldflow.notificacoes.dlq"


def _process(routing_key: str, payload: dict, event_id: str) -> None:
    db = SessionLocal()
    try:
        existente = notif_repository.get_by_event_id(db, event_id)
        if existente is not None:
            logger.info(
                "[worker] evento ja processado event_id=%s — pulando",
                event_id,
            )
            return

        persist_event(db, routing_key, payload, event_id)
        if routing_key == "prestador.perfil.enviado":
            validar_perfil_prestador(db, payload, get_event_publisher())
        elif routing_key == "candidatura.aceita":
            rejeitar_concorrentes(db, payload, get_event_publisher())
        # Commit ao final do processamento da mensagem: idempotencia da
        # notificacao + acoes derivadas viram uma unica transacao.
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
        logger.exception("[worker] payload invalido — descartando")
        channel.basic_ack(delivery_tag=method.delivery_tag)
        return

    event_id = _extract_event_id(properties, payload)
    if not event_id:
        logger.warning(
            "[worker] mensagem sem event_id routing_key=%s — descartando",
            routing_key,
        )
        channel.basic_ack(delivery_tag=method.delivery_tag)
        return

    try:
        _process(routing_key, payload, event_id)
        channel.basic_ack(delivery_tag=method.delivery_tag)
    except Exception:
        logger.exception(
            "[worker] falha ao processar %s id=%s — indo pra DLQ",
            routing_key,
            event_id,
        )
        channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)


def _connect_with_retry(max_attempts: int = 30, delay_seconds: float = 2.0):
    params = pika.URLParameters(settings.rabbitmq_url)
    for attempt in range(1, max_attempts + 1):
        try:
            return pika.BlockingConnection(params)
        except AMQPConnectionError as exc:
            logger.warning(
                "[worker] rabbit indisponivel (tentativa %s/%s): %s",
                attempt,
                max_attempts,
                exc,
            )
            time.sleep(delay_seconds)
    raise RuntimeError("Nao foi possivel conectar ao RabbitMQ")


def _declare_topology(connection, exchange: str):
    """Declara exchange principal, DLX, DLQ e fila principal com dead-letter.

    Se a fila principal ja existe com argumentos diferentes (instancia antiga),
    cai pra modo legacy sem DLQ e loga instrucao para reset.
    """
    channel = connection.channel()
    channel.exchange_declare(
        exchange=exchange, exchange_type="topic", durable=True
    )
    channel.exchange_declare(
        exchange=DLX_NAME, exchange_type="fanout", durable=True
    )
    channel.queue_declare(queue=DLQ_NAME, durable=True)
    channel.queue_bind(queue=DLQ_NAME, exchange=DLX_NAME)

    try:
        channel.queue_declare(
            queue=QUEUE_NAME,
            durable=True,
            arguments={"x-dead-letter-exchange": DLX_NAME},
        )
    except ChannelClosedByBroker as exc:
        if exc.reply_code == 406:
            logger.warning(
                "[worker] fila '%s' existe sem DLQ. "
                "Rode 'docker compose down -v' para resetar o broker e ativar a DLQ. "
                "Seguindo em modo legacy.",
                QUEUE_NAME,
            )
            channel = connection.channel()
            channel.exchange_declare(
                exchange=exchange, exchange_type="topic", durable=True
            )
            channel.queue_declare(queue=QUEUE_NAME, durable=True)
        else:
            raise

    for pattern in BINDINGS:
        channel.queue_bind(
            queue=QUEUE_NAME, exchange=exchange, routing_key=pattern
        )
    channel.basic_qos(prefetch_count=10)
    return channel


def run() -> None:
    if not settings.rabbitmq_url:
        raise RuntimeError("RABBITMQ_URL nao configurada")

    connection = _connect_with_retry()
    exchange = settings.mom_exchange
    channel = _declare_topology(connection, exchange)
    channel.basic_consume(queue=QUEUE_NAME, on_message_callback=_on_message)

    logger.info(
        "[worker] consumindo exchange=%s queue=%s bindings=%s dlq=%s",
        exchange,
        QUEUE_NAME,
        BINDINGS,
        DLQ_NAME,
    )
    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        logger.info("[worker] interrompido pelo usuario")
    finally:
        connection.close()
