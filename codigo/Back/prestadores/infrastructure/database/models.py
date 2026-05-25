from sqlalchemy import (
    JSON,
    Column,
    DateTime,
    Enum as SqlEnum,
    ForeignKey,
    Integer,
    String,
    Text,
)

from core.database import Base
from prestadores.domain.entities import StatusPerfil


class PerfilPrestador(Base):
    __tablename__ = "perfis_prestador"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    bio = Column(Text, nullable=True)
    anos_experiencia = Column(Integer, nullable=True)
    especialidades = Column(JSON, nullable=False, default=list)
    certificacoes = Column(JSON, nullable=False, default=list)
    cnh_categoria = Column(String, nullable=True)
    regioes_atuacao = Column(JSON, nullable=False, default=list)
    equipamentos_proprios = Column(JSON, nullable=False, default=list)
    status = Column(
        SqlEnum(StatusPerfil, name="status_perfil"),
        nullable=False,
        default=StatusPerfil.INCOMPLETO,
    )
    motivo_reprovacao = Column(Text, nullable=True)
    enviado_em = Column(DateTime(timezone=True), nullable=True)
    avaliado_em = Column(DateTime(timezone=True), nullable=True)
