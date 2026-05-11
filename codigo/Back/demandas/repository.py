from sqlalchemy.orm import Session

from demandas.model import Demanda


def get_by_id(db: Session, demanda_id: int) -> Demanda | None:
    return db.query(Demanda).filter(Demanda.id == demanda_id).first()


def get_all(db: Session) -> list[Demanda]:
    return db.query(Demanda).order_by(Demanda.id).all()


def save(db: Session, demanda: Demanda) -> Demanda:
    db.add(demanda)
    db.commit()
    db.refresh(demanda)
    return demanda


def delete(db: Session, demanda: Demanda) -> None:
    db.delete(demanda)
    db.commit()
