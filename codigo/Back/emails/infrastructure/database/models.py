from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Integer, String

from core.database import Base


class EmailEnviado(Base):
    """Auditoria + idempotencia do worker de email.

    A unique constraint em `event_id` garante que um redelivery do broker (ou
    duas entregas concorrentes) nao gere email duplicado: o consumer checa esta
    tabela antes de enviar, e o UNIQUE e a segunda barreira contra race.
    """

    __tablename__ = "emails_enviados"

    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(String, nullable=False, unique=True, index=True)
    routing_key = Column(String, nullable=False, index=True)
    destinatario = Column(String, nullable=False)
    assunto = Column(String, nullable=False)
    status = Column(String, nullable=False, default="ENVIADO")
    enviado_em = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(tz=timezone.utc),
    )
