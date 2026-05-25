import logging

from core.config import settings
from mom.interface import EventPublisher
from mom.noop import NoopEventPublisher
from mom.rabbitmq import RabbitMQEventPublisher

logger = logging.getLogger(__name__)

_publisher: EventPublisher | None = None


def _build_publisher() -> EventPublisher:
    url = settings.rabbitmq_url
    if not url:
        logger.warning("RABBITMQ_URL nao configurada — usando NoopEventPublisher")
        return NoopEventPublisher()
    return RabbitMQEventPublisher(url=url, exchange=settings.mom_exchange)


def get_event_publisher() -> EventPublisher:
    global _publisher
    if _publisher is None:
        _publisher = _build_publisher()
    return _publisher


def shutdown_event_publisher() -> None:
    global _publisher
    if _publisher is not None:
        _publisher.close()
        _publisher = None
