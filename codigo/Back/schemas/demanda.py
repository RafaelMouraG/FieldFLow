from datetime import date
from typing import Optional

from pydantic import BaseModel, ConfigDict

from models.demanda import DemandaStatus


class DemandaBase(BaseModel):
    titulo: str
    descricao: str
    origem: str
    destino: Optional[str] = None
    area_hectares: float
    valor_recompensa: float
    tipo_servico: str
    data_limite: Optional[date] = None


class DemandaCreate(DemandaBase):
    pass


class DemandaResponse(DemandaBase):
    id: int
    status: DemandaStatus

    model_config = ConfigDict(from_attributes=True)


class DemandaStatusUpdate(BaseModel):
    status: DemandaStatus
