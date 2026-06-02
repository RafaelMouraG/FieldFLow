from datetime import date
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

from demandas.domain.entities import DemandaStatus, UnidadePagamento


class DemandaBase(BaseModel):
    titulo: str
    descricao: str
    origem: str
    destino: Optional[str] = None
    origem_lat: Optional[float] = None
    origem_lng: Optional[float] = None
    destino_lat: Optional[float] = None
    destino_lng: Optional[float] = None
    area_hectares: float
    valor_recompensa: Optional[float] = Field(default=None, ge=0)
    unidade_pagamento: UnidadePagamento = UnidadePagamento.FIXO
    tipo_servico: str
    data_limite: Optional[date] = None

    @model_validator(mode="after")
    def _valida_valor_vs_unidade(self):
        if (
            self.unidade_pagamento != UnidadePagamento.A_COMBINAR
            and self.valor_recompensa is None
        ):
            raise ValueError(
                "valor_recompensa eh obrigatorio quando unidade_pagamento "
                "nao for A_COMBINAR"
            )
        return self


class DemandaCreate(DemandaBase):
    pass


class DemandaResponse(DemandaBase):
    id: int
    cliente_id: int
    status: DemandaStatus
    prestador_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


class DemandaStatusUpdate(BaseModel):
    status: DemandaStatus
    prestador_id: Optional[int] = None
