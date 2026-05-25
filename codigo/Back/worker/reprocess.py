"""Reprocessamento manual da DLQ.

Drena a fila `fieldflow.notificacoes.dlq` republicando cada mensagem no
exchange principal com a routing key original (lida do header `x-death`
adicionado pelo broker no momento do dead-letter).

Uso operacional: `python -m worker reprocess-dlq` (dentro do container).
"""
import logging

import pika
from pika.exceptions import UnroutableError

from core.config import settings
from worker.consumer import DLQ_NAME, _connect_with_retry

logger = logging.getLogger(__name__)

MAX_MESSAGES = 1000


def _original_routing_key(properties) -> str | None:
    if not properties or not properties.headers:
        return None
    x_death = properties.headers.get("x-death")
    if not x_death or not isinstance(x_death, list):
        return None
    routing_keys = x_death[0].get("routing-keys")
    if not routing_keys or not isinstance(routing_keys, list):
        return None
    return routing_keys[0]


def _strip_x_death(properties: pika.BasicProperties) -> pika.BasicProperties:
    headers = dict(properties.headers or {})
    headers.pop("x-death", None)
    headers.pop("x-first-death-exchange", None)
    headers.pop("x-first-death-queue", None)
    headers.pop("x-first-death-reason", None)
    return pika.BasicProperties(
        content_type=properties.content_type,
        delivery_mode=properties.delivery_mode or 2,
        message_id=properties.message_id,
        headers=headers or None,
    )


def reprocess_dlq() -> None:
    if not settings.rabbitmq_url:
        raise RuntimeError("RABBITMQ_URL nao configurada")

    connection = _connect_with_retry()
    try:
        pub_channel = connection.channel()
        pub_channel.confirm_delivery()
        pub_channel.exchange_declare(
            exchange=settings.mom_exchange,
            exchange_type="topic",
            durable=True,
        )

        get_channel = connection.channel()
        republicadas = 0
        ignoradas = 0

        for _ in range(MAX_MESSAGES):
            method, properties, body = get_channel.basic_get(
                queue=DLQ_NAME, auto_ack=False
            )
            if method is None:
                break

            routing_key = _original_routing_key(properties)
            if routing_key is None:
                logger.warning(
                    "[reprocess-dlq] mensagem sem x-death/routing-keys "
                    "delivery_tag=%s — devolvendo pra DLQ",
                    method.delivery_tag,
                )
                get_channel.basic_nack(
                    delivery_tag=method.delivery_tag, requeue=True
                )
                ignoradas += 1
                # Sem routing key nao da pra republicar; parar evita loop
                # consumindo a mesma mensagem repetidamente.
                break

            try:
                pub_channel.basic_publish(
                    exchange=settings.mom_exchange,
                    routing_key=routing_key,
                    body=body,
                    properties=_strip_x_death(properties),
                    mandatory=True,
                )
            except UnroutableError:
                logger.warning(
                    "[reprocess-dlq] routing_key=%s nao casa com nenhuma "
                    "binding atual — devolvendo pra DLQ",
                    routing_key,
                )
                get_channel.basic_nack(
                    delivery_tag=method.delivery_tag, requeue=True
                )
                ignoradas += 1
                break
            except Exception:
                logger.exception(
                    "[reprocess-dlq] falha ao republicar routing_key=%s "
                    "message_id=%s — devolvendo pra DLQ",
                    routing_key,
                    properties.message_id if properties else None,
                )
                get_channel.basic_nack(
                    delivery_tag=method.delivery_tag, requeue=True
                )
                break

            get_channel.basic_ack(delivery_tag=method.delivery_tag)
            republicadas += 1
            logger.info(
                "[reprocess-dlq] republicado routing_key=%s message_id=%s",
                routing_key,
                properties.message_id if properties else None,
            )

        logger.info(
            "[reprocess-dlq] fim: republicadas=%s ignoradas=%s",
            republicadas,
            ignoradas,
        )
    finally:
        connection.close()
