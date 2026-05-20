from abc import ABC, abstractmethod
from typing import Any


class EventPublisher(ABC):
    """Interface do MOM (Message Oriented Middleware).

    Implementações concretas (RabbitMQ, Redis, etc.) devem publicar o evento
    de forma assíncrona em relação ao consumidor, sem bloquear o caso de uso.
    """

    @abstractmethod
    def publish(self, event_type: str, payload: dict[str, Any]) -> None: ...

    def close(self) -> None:
        return None
