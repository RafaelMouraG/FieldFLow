from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from avaliacoes.domain.entities import NOTA_MAX, NOTA_MIN


class AvaliacaoCreate(BaseModel):
    nota: int = Field(ge=NOTA_MIN, le=NOTA_MAX)
    comentario: Optional[str] = Field(default=None, max_length=2000)


class AvaliacaoResponse(BaseModel):
    id: int
    demanda_id: int
    autor_id: int
    prestador_id: int
    nota: int
    comentario: Optional[str] = None
    criado_em: datetime

    model_config = ConfigDict(from_attributes=True)
