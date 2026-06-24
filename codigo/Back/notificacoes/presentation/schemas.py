from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class NotificacaoResponse(BaseModel):
    id: int
    event_id: str
    event_type: str
    routing_key: str
    payload: dict[str, Any]
    criado_em: datetime
    # Calculada por usuario em listar_para_usuario (id <= marca d'agua).
    lida: bool = False

    model_config = ConfigDict(from_attributes=True)
