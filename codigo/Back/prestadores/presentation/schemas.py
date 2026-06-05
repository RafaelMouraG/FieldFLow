from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field

from prestadores.domain.entities import StatusPerfil


class PerfilSubmit(BaseModel):
    bio: Optional[str] = Field(default=None, max_length=2000)
    anos_experiencia: int = Field(ge=0, le=80)
    especialidades: list[str] = Field(default_factory=list)
    certificacoes: list[dict[str, Any]] = Field(default_factory=list)
    cnh_categoria: Optional[str] = None
    regioes_atuacao: list[str] = Field(default_factory=list)
    equipamentos_proprios: list[str] = Field(default_factory=list)


class PerfilResponse(BaseModel):
    usuario_id: int
    bio: Optional[str] = None
    anos_experiencia: Optional[int] = None
    especialidades: list[Any]
    certificacoes: list[Any]
    cnh_categoria: Optional[str] = None
    regioes_atuacao: list[Any]
    equipamentos_proprios: list[Any]
    status: StatusPerfil
    motivo_reprovacao: Optional[str] = None
    enviado_em: Optional[datetime] = None
    avaliado_em: Optional[datetime] = None
    # Reputacao agregada (preenchida no use case get_perfil).
    nota_media: Optional[float] = None
    total_avaliacoes: int = 0

    model_config = ConfigDict(from_attributes=True)
