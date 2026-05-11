from sqlalchemy.orm import Session

from models.demanda import Demanda, DemandaStatus
from schemas.demanda import DemandaCreate


def create_demanda(db: Session, payload: DemandaCreate) -> Demanda:
    demanda = Demanda(**payload.model_dump())
    db.add(demanda)
    db.commit()
    db.refresh(demanda)
    return demanda


def list_demandas(db: Session) -> list[Demanda]:
    return db.query(Demanda).order_by(Demanda.id).all()


def get_demanda(db: Session, demanda_id: int) -> Demanda | None:
    return db.query(Demanda).filter(Demanda.id == demanda_id).first()


def update_demanda_status(
    db: Session, demanda_id: int, status: DemandaStatus, prestador_id: int | None = None
) -> Demanda | None:
    demanda = get_demanda(db, demanda_id)
    if not demanda:
        return None
    demanda.status = status
    if prestador_id is not None:
        demanda.prestador_id = prestador_id
    db.commit()
    db.refresh(demanda)
    return demanda


def update_demanda(
    db: Session, demanda_id: int, payload: DemandaCreate
) -> Demanda | None:
    demanda = get_demanda(db, demanda_id)
    if not demanda:
        return None
    
    for key, value in payload.model_dump().items():
        setattr(demanda, key, value)
        
    db.commit()
    db.refresh(demanda)
    return demanda


def delete_demanda(db: Session, demanda_id: int) -> bool:
    demanda = get_demanda(db, demanda_id)
    if not demanda:
        return False
        
    db.delete(demanda)
    db.commit()
    return True
