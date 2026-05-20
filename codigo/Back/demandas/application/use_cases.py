from sqlalchemy.orm import Session

from demandas.domain.entities import DemandaStatus
from demandas.infrastructure.database import repository
from demandas.infrastructure.database.models import Demanda
from demandas.presentation.schemas import DemandaCreate
from mom.interface import EventPublisher


def _demanda_payload(demanda: Demanda) -> dict:
    return {
        "id": demanda.id,
        "cliente_id": demanda.cliente_id,
        "prestador_id": demanda.prestador_id,
        "titulo": demanda.titulo,
        "tipo_servico": demanda.tipo_servico,
        "status": demanda.status.value,
    }


def create_demanda(
    db: Session, payload: DemandaCreate, publisher: EventPublisher
) -> Demanda:
    demanda = Demanda(**payload.model_dump())
    saved = repository.save(db, demanda)
    publisher.publish("demanda.criada", _demanda_payload(saved))
    return saved


def list_demandas(db: Session) -> list[Demanda]:
    return repository.get_all(db)


def get_demanda(db: Session, demanda_id: int) -> Demanda | None:
    return repository.get_by_id(db, demanda_id)


def update_demanda_status(
    db: Session,
    demanda_id: int,
    status: DemandaStatus,
    publisher: EventPublisher,
    prestador_id: int | None = None,
) -> Demanda | None:
    demanda = repository.get_by_id(db, demanda_id)
    if not demanda:
        return None
    status_anterior = demanda.status
    demanda.status = status
    if prestador_id is not None:
        demanda.prestador_id = prestador_id
    saved = repository.save(db, demanda)

    payload = _demanda_payload(saved)
    payload["status_anterior"] = status_anterior.value
    publisher.publish(f"demanda.status.{status.value.lower()}", payload)
    return saved


def update_demanda(
    db: Session,
    demanda_id: int,
    payload: DemandaCreate,
    publisher: EventPublisher,
) -> Demanda | None:
    demanda = repository.get_by_id(db, demanda_id)
    if not demanda:
        return None
    for key, value in payload.model_dump().items():
        setattr(demanda, key, value)
    saved = repository.save(db, demanda)
    publisher.publish("demanda.atualizada", _demanda_payload(saved))
    return saved


def delete_demanda(
    db: Session, demanda_id: int, publisher: EventPublisher
) -> bool:
    demanda = repository.get_by_id(db, demanda_id)
    if not demanda:
        return False
    repository.delete(db, demanda)
    publisher.publish("demanda.removida", {"id": demanda_id})
    return True
