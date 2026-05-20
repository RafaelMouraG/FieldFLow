from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from core.database import get_db
from demandas.application.use_cases import (
    create_demanda,
    delete_demanda,
    get_demanda,
    list_demandas,
    update_demanda,
    update_demanda_status,
)
from demandas.presentation.schemas import (
    DemandaCreate,
    DemandaResponse,
    DemandaStatusUpdate,
)
from mom.dependencies import get_event_publisher
from mom.interface import EventPublisher

router = APIRouter(prefix="/demandas", tags=["demandas"])


@router.post("", response_model=DemandaResponse, status_code=status.HTTP_201_CREATED)
def criar_demanda(
    payload: DemandaCreate,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
):
    return create_demanda(db, payload, publisher)


@router.get("", response_model=list[DemandaResponse])
def listar_demandas(db: Session = Depends(get_db)):
    return list_demandas(db)


@router.get("/{demanda_id}", response_model=DemandaResponse)
def obter_demanda(demanda_id: int, db: Session = Depends(get_db)):
    demanda = get_demanda(db, demanda_id)
    if not demanda:
        raise HTTPException(status_code=404, detail="Demanda nao encontrada")
    return demanda


@router.patch("/{demanda_id}/status", response_model=DemandaResponse)
def atualizar_status(
    demanda_id: int,
    payload: DemandaStatusUpdate,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
):
    demanda = update_demanda_status(
        db, demanda_id, payload.status, publisher, payload.prestador_id
    )
    if not demanda:
        raise HTTPException(status_code=404, detail="Demanda nao encontrada")
    return demanda


@router.put("/{demanda_id}", response_model=DemandaResponse)
def atualizar_demanda(
    demanda_id: int,
    payload: DemandaCreate,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
):
    demanda = update_demanda(db, demanda_id, payload, publisher)
    if not demanda:
        raise HTTPException(status_code=404, detail="Demanda nao encontrada")
    return demanda


@router.delete("/{demanda_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_demanda(
    demanda_id: int,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
):
    sucesso = delete_demanda(db, demanda_id, publisher)
    if not sucesso:
        raise HTTPException(status_code=404, detail="Demanda nao encontrada")
