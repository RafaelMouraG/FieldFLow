import json
import logging
from typing import Any

import pika
from pika.exceptions import AMQPError

from mom.interface import EventPublisher

logger = logging.getLogger(__name__)


class RabbitMQEventPublisher(EventPublisher):
    """Publisher baseado em RabbitMQ usando um topic exchange."""

    def __init__(self, url: str, exchange: str = "fieldflow.events") -> None:
        self._url = url
        self._exchange = exchange
        self._connection: pika.BlockingConnection | None = None
        self._channel = None

    def _ensure_channel(self):
        if self._connection and self._connection.is_open and self._channel:
            return self._channel
        params = pika.URLParameters(self._url)
        self._connection = pika.BlockingConnection(params)
        self._channel = self._connection.channel()
        self._channel.exchange_declare(
            exchange=self._exchange, exchange_type="topic", durable=True
        )
        return self._channel

    def _do_publish(
        self, event_type: str, payload: dict[str, Any], event_id: str
    ) -> None:
        body = json.dumps(payload, default=str).encode("utf-8")
        try:
            channel = self._ensure_channel()
            channel.basic_publish(
                exchange=self._exchange,
                routing_key=event_type,
                body=body,
                properties=pika.BasicProperties(
                    content_type="application/json",
                    delivery_mode=2,
                    message_id=event_id,
                ),
            )
            logger.info(
                "[MOM] published event=%s id=%s", event_type, event_id
            )
        except AMQPError as exc:
            logger.error("[MOM] falha ao publicar %s: %s", event_type, exc)
            self.close()

    def close(self) -> None:
        try:
            if self._connection and self._connection.is_open:
                self._connection.close()
        finally:
            self._connection = None
            self._channel = None
