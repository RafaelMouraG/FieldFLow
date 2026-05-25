from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from candidaturas.domain.entities import StatusCandidatura


class CandidaturaCreate(BaseModel):
    mensagem: Optional[str] = Field(default=None, max_length=2000)
    valor_proposto: Optional[float] = Field(default=None, ge=0)


class CandidaturaResponse(BaseModel):
    id: int
    demanda_id: int
    prestador_id: int
    mensagem: Optional[str] = None
    valor_proposto: Optional[float] = None
    status: StatusCandidatura
    criado_em: datetime

    model_config = ConfigDict(from_attributes=True)
