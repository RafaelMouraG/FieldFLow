from sqlalchemy.orm import Session

from candidaturas.domain.entities import StatusCandidatura
from candidaturas.infrastructure.database.models import Candidatura


def get_by_id(db: Session, candidatura_id: int) -> Candidatura | None:
    return (
        db.query(Candidatura).filter(Candidatura.id == candidatura_id).first()
    )


def get_by_demanda_e_prestador(
    db: Session, demanda_id: int, prestador_id: int
) -> Candidatura | None:
    return (
        db.query(Candidatura)
        .filter(
            Candidatura.demanda_id == demanda_id,
            Candidatura.prestador_id == prestador_id,
        )
        .first()
    )


def listar_por_demanda(db: Session, demanda_id: int) -> list[Candidatura]:
    return (
        db.query(Candidatura)
        .filter(Candidatura.demanda_id == demanda_id)
        .order_by(Candidatura.criado_em.desc())
        .all()
    )


def listar_pendentes_da_demanda(
    db: Session, demanda_id: int, excluir_id: int | None = None
) -> list[Candidatura]:
    query = db.query(Candidatura).filter(
        Candidatura.demanda_id == demanda_id,
        Candidatura.status == StatusCandidatura.PENDENTE,
    )
    if excluir_id is not None:
        query = query.filter(Candidatura.id != excluir_id)
    return query.all()


def listar_por_prestador(db: Session, prestador_id: int) -> list[Candidatura]:
    return (
        db.query(Candidatura)
        .filter(Candidatura.prestador_id == prestador_id)
        .order_by(Candidatura.criado_em.desc())
        .all()
    )


def save(db: Session, candidatura: Candidatura) -> Candidatura:
    # Sem commit: a unidade de trabalho fica a cargo do use case (atomicidade
    # entre multiplas tabelas) ou do get_db (boundary da request).
    db.add(candidatura)
    db.flush()
    db.refresh(candidatura)
    return candidatura
