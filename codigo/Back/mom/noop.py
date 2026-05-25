import logging
from typing import Any

from mom.interface import EventPublisher

logger = logging.getLogger(__name__)


class NoopEventPublisher(EventPublisher):
    """Publisher que apenas loga o evento — usado quando o broker está indisponível
    ou em ambiente de testes."""

    def _do_publish(
        self, event_type: str, payload: dict[str, Any], event_id: str
    ) -> None:
        logger.info(
            "[MOM-NOOP] event=%s id=%s payload=%s",
            event_type,
            event_id,
            payload,
        )
