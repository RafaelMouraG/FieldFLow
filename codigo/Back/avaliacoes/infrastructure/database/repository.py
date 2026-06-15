from sqlalchemy import func
from sqlalchemy.orm import Session

from avaliacoes.infrastructure.database.models import Avaliacao


def get_by_demanda(db: Session, demanda_id: int) -> Avaliacao | None:
    return (
        db.query(Avaliacao).filter(Avaliacao.demanda_id == demanda_id).first()
    )


def listar_por_prestador(db: Session, prestador_id: int) -> list[Avaliacao]:
    return (
        db.query(Avaliacao)
        .filter(Avaliacao.prestador_id == prestador_id)
        .order_by(Avaliacao.criado_em.desc())
        .all()
    )


def media_e_total(db: Session, prestador_id: int) -> tuple[float | None, int]:
    """Retorna (media_das_notas, total) de um prestador. media e None se 0."""
    media, total = (
        db.query(func.avg(Avaliacao.nota), func.count(Avaliacao.id))
        .filter(Avaliacao.prestador_id == prestador_id)
        .one()
    )
    return (float(media) if media is not None else None, int(total))


def save(db: Session, avaliacao: Avaliacao) -> Avaliacao:
    # Sem commit: unidade de trabalho controlada pelo use case / get_db.
    db.add(avaliacao)
    db.flush()
    db.refresh(avaliacao)
    return avaliacao
