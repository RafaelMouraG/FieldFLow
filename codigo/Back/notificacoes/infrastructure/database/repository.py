from sqlalchemy.orm import Session

from notificacoes.infrastructure.database.models import Notificacao


def save(db: Session, notificacao: Notificacao) -> Notificacao:
    # Sem commit: o consumer (worker._process) e quem fecha a transacao
    # depois de todos os efeitos de um evento (persist + acoes derivadas).
    db.add(notificacao)
    db.flush()
    db.refresh(notificacao)
    return notificacao


def get_by_event_id(db: Session, event_id: str) -> Notificacao | None:
    return (
        db.query(Notificacao).filter(Notificacao.event_id == event_id).first()
    )


def get_all(db: Session, limit: int = 100) -> list[Notificacao]:
    return (
        db.query(Notificacao)
        .order_by(Notificacao.id.desc())
        .limit(limit)
        .all()
    )
