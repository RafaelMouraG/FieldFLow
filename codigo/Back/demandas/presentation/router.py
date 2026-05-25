from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user
from core.database import get_db
from demandas.application.use_cases import (
    OperacaoNaoPermitidaError,
    TransicaoStatusInvalidaError,
    create_demanda,
    delete_demanda,
    get_demanda,
    list_demandas_do_cliente,
    list_demandas_para_prestador,
    list_demandas_pendentes,
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
from usuarios.domain.entities import TipoUsuario
from usuarios.infrastructure.database.models import Usuario

router = APIRouter(prefix="/demandas", tags=["demandas"])


@router.post(
    "", response_model=DemandaResponse, status_code=status.HTTP_201_CREATED
)
def criar_demanda(
    payload: DemandaCreate,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
    current_user: Usuario = Depends(get_current_user),
):
    if current_user.tipo != TipoUsuario.CLIENTE:
        raise HTTPException(
            status_code=403, detail="Apenas clientes podem criar demandas"
        )
    return create_demanda(db, payload, current_user.id, publisher)


@router.get("", response_model=list[DemandaResponse])
def listar_demandas(
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    if current_user.tipo == TipoUsuario.CLIENTE:
        return list_demandas_do_cliente(db, current_user.id)
    if current_user.tipo == TipoUsuario.PRESTADOR:
        return list_demandas_para_prestador(db, current_user.id)
    return list_demandas_pendentes(db)


@router.get("/{demanda_id}", response_model=DemandaResponse)
def obter_demanda(
    demanda_id: int,
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),  # noqa: ARG001
):
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
    current_user: Usuario = Depends(get_current_user),
):
    try:
        demanda = update_demanda_status(
            db, demanda_id, current_user.id, payload.status, publisher
        )
    except TransicaoStatusInvalidaError as exc:
        raise HTTPException(status_code=409, detail=str(exc))
    except OperacaoNaoPermitidaError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    if not demanda:
        raise HTTPException(status_code=404, detail="Demanda nao encontrada")
    return demanda


@router.put("/{demanda_id}", response_model=DemandaResponse)
def atualizar_demanda(
    demanda_id: int,
    payload: DemandaCreate,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
    current_user: Usuario = Depends(get_current_user),
):
    try:
        demanda = update_demanda(
            db, demanda_id, current_user.id, payload, publisher
        )
    except OperacaoNaoPermitidaError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    except TransicaoStatusInvalidaError as exc:
        raise HTTPException(status_code=409, detail=str(exc))
    if not demanda:
        raise HTTPException(status_code=404, detail="Demanda nao encontrada")
    return demanda


@router.delete("/{demanda_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_demanda(
    demanda_id: int,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
    current_user: Usuario = Depends(get_current_user),
):
    try:
        sucesso = delete_demanda(db, demanda_id, current_user.id, publisher)
    except OperacaoNaoPermitidaError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    if not sucesso:
        raise HTTPException(status_code=404, detail="Demanda nao encontrada")
