from sqlalchemy.orm import Session

from emails.infrastructure.database.models import EmailEnviado


def save(db: Session, email: EmailEnviado) -> EmailEnviado:
    # Sem commit: o consumer (email worker) fecha a transacao depois que o
    # envio do email e o registro de auditoria viram uma unica unidade.
    db.add(email)
    db.flush()
    db.refresh(email)
    return email


def get_by_event_id(db: Session, event_id: str) -> EmailEnviado | None:
    return (
        db.query(EmailEnviado)
        .filter(EmailEnviado.event_id == event_id)
        .first()
    )


def get_all(db: Session, limit: int = 100) -> list[EmailEnviado]:
    return (
        db.query(EmailEnviado)
        .order_by(EmailEnviado.id.desc())
        .limit(limit)
        .all()
    )
