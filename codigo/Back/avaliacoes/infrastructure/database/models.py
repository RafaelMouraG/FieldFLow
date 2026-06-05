from datetime import datetime, timezone

from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    Text,
    UniqueConstraint,
)

from core.database import Base


class Avaliacao(Base):
    __tablename__ = "avaliacoes"
    __table_args__ = (
        # Uma avaliacao por demanda (a demanda tem um unico cliente/prestador).
        UniqueConstraint("demanda_id", name="uq_avaliacao_demanda"),
    )

    id = Column(Integer, primary_key=True, index=True)
    demanda_id = Column(
        Integer,
        ForeignKey("demandas.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    autor_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    prestador_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    nota = Column(Integer, nullable=False)
    comentario = Column(Text, nullable=True)
    criado_em = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(tz=timezone.utc),
    )
