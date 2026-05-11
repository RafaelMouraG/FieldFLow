from sqlalchemy.orm import Session

from demandas import repository
from demandas.model import Demanda, DemandaStatus
from demandas.schemas import DemandaCreate


def create_demanda(db: Session, payload: DemandaCreate) -> Demanda:
    demanda = Demanda(**payload.model_dump())
    return repository.save(db, demanda)


def list_demandas(db: Session) -> list[Demanda]:
    return repository.get_all(db)


def get_demanda(db: Session, demanda_id: int) -> Demanda | None:
    return repository.get_by_id(db, demanda_id)


def update_demanda_status(
    db: Session, demanda_id: int, status: DemandaStatus, prestador_id: int | None = None
) -> Demanda | None:
    demanda = repository.get_by_id(db, demanda_id)
    if not demanda:
        return None
    demanda.status = status
    if prestador_id is not None:
        demanda.prestador_id = prestador_id
    return repository.save(db, demanda)


def update_demanda(
    db: Session, demanda_id: int, payload: DemandaCreate
) -> Demanda | None:
    demanda = repository.get_by_id(db, demanda_id)
    if not demanda:
        return None
    for key, value in payload.model_dump().items():
        setattr(demanda, key, value)
    return repository.save(db, demanda)


def delete_demanda(db: Session, demanda_id: int) -> bool:
    demanda = repository.get_by_id(db, demanda_id)
    if not demanda:
        return False
    repository.delete(db, demanda)
    return True
