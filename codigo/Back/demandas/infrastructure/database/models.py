from sqlalchemy import (
    Column,
    Date,
    Enum as SqlEnum,
    Float,
    ForeignKey,
    Integer,
    String,
)

from core.database import Base
from demandas.domain.entities import DemandaStatus, UnidadePagamento


class Demanda(Base):
    __tablename__ = "demandas"

    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    prestador_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    titulo = Column(String, nullable=False)
    descricao = Column(String, nullable=False)
    origem = Column(String, nullable=False)
    destino = Column(String, nullable=True)
    # Coordenadas do local da tarefa (talhao). O texto origem/destino e o rotulo
    # legivel; lat/lng dao o ponto exato para o prestador navegar (Maps).
    origem_lat = Column(Float, nullable=True)
    origem_lng = Column(Float, nullable=True)
    destino_lat = Column(Float, nullable=True)
    destino_lng = Column(Float, nullable=True)
    area_hectares = Column(Float, nullable=False)
    valor_recompensa = Column(Float, nullable=True)
    unidade_pagamento = Column(
        SqlEnum(UnidadePagamento, name="unidade_pagamento"),
        nullable=False,
        default=UnidadePagamento.FIXO,
    )
    tipo_servico = Column(String, nullable=False)
    data_limite = Column(Date, nullable=True)
    status = Column(
        SqlEnum(DemandaStatus, name="demanda_status"),
        default=DemandaStatus.PENDENTE,
        nullable=False,
    )
