from enum import Enum

from sqlalchemy import Column, Date, Enum as SqlEnum, Float, Integer, String

from database.database import Base


class DemandaStatus(str, Enum):
    PENDENTE = "PENDENTE"
    ACEITO = "ACEITO"
    EM_EXECUCAO = "EM_EXECUCAO"
    CONCLUIDO = "CONCLUIDO"


class Demanda(Base):
    __tablename__ = "demandas"

    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, nullable=False, index=True)
    prestador_id = Column(Integer, nullable=True, index=True)
    titulo = Column(String, nullable=False)
    descricao = Column(String, nullable=False)
    origem = Column(String, nullable=False)
    destino = Column(String, nullable=True)
    area_hectares = Column(Float, nullable=False)
    valor_recompensa = Column(Float, nullable=False)
    tipo_servico = Column(String, nullable=False)
    data_limite = Column(Date, nullable=True)
    status = Column(
        SqlEnum(DemandaStatus, name="demanda_status"),
        default=DemandaStatus.PENDENTE,
        nullable=False,
    )
