import uuid
from abc import ABC, abstractmethod
from typing import Any


class EventPublisher(ABC):
    """Interface do MOM (Message Oriented Middleware).

    Implementações concretas (RabbitMQ, Redis, etc.) devem publicar o evento
    de forma assíncrona em relação ao consumidor, sem bloquear o caso de uso.

    Cada mensagem carrega um `event_id` (UUID) único. O consumidor usa esse id
    como chave de deduplicacao (idempotencia).
    """

    def publish(
        self,
        event_type: str,
        payload: dict[str, Any],
        event_id: str | None = None,
    ) -> str:
        event_id = event_id or str(uuid.uuid4())
        enriched = {"event_id": event_id, **payload}
        self._do_publish(event_type, enriched, event_id)
        return event_id

    @abstractmethod
    def _do_publish(
        self, event_type: str, payload: dict[str, Any], event_id: str
    ) -> None: ...

    def close(self) -> None:
        return None
