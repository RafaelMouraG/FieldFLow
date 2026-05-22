from datetime import datetime, timezone

from sqlalchemy import (
    Column,
    DateTime,
    Enum as SqlEnum,
    Float,
    ForeignKey,
    Integer,
    Text,
    UniqueConstraint,
)

from candidaturas.domain.entities import StatusCandidatura
from core.database import Base


class Candidatura(Base):
    __tablename__ = "candidaturas"
    __table_args__ = (
        UniqueConstraint("demanda_id", "prestador_id", name="uq_candidatura_demanda_prestador"),
    )

    id = Column(Integer, primary_key=True, index=True)
    demanda_id = Column(
        Integer,
        ForeignKey("demandas.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    prestador_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    mensagem = Column(Text, nullable=True)
    valor_proposto = Column(Float, nullable=True)
    status = Column(
        SqlEnum(StatusCandidatura, name="status_candidatura"),
        nullable=False,
        default=StatusCandidatura.PENDENTE,
    )
    criado_em = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(tz=timezone.utc),
    )
