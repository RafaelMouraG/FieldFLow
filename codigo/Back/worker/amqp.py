"""Helpers AMQP compartilhados pelos consumidores (negocio e email)."""
import logging
import time

import pika
from pika.exceptions import AMQPConnectionError

from core.config import settings

logger = logging.getLogger(__name__)


def connect_with_retry(
    max_attempts: int = 30, delay_seconds: float = 2.0
) -> pika.BlockingConnection:
    """Conecta ao RabbitMQ tentando varias vezes (o broker pode subir depois)."""
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
