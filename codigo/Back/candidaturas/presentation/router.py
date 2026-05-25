from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user
from candidaturas.application.use_cases import (
    CandidaturaDuplicadaError,
    CandidaturaNaoEncontradaError,
    DemandaInvalidaError,
    EstadoInvalidoError,
    OperacaoNaoPermitidaError,
    PrestadorNaoAprovadoError,
    aceitar_candidatura,
    cancelar_candidatura,
    candidatar,
    listar_da_demanda,
    listar_minhas,
)
from candidaturas.presentation.schemas import (
    CandidaturaCreate,
    CandidaturaResponse,
)
from core.database import get_db
from demandas.infrastructure.database import repository as demandas_repository
from mom.dependencies import get_event_publisher
from mom.interface import EventPublisher
from usuarios.domain.entities import TipoUsuario
from usuarios.infrastructure.database.models import Usuario

router = APIRouter(tags=["candidaturas"])


@router.post(
    "/demandas/{demanda_id}/candidaturas",
    response_model=CandidaturaResponse,
    status_code=status.HTTP_201_CREATED,
)
def candidatar_se(
    demanda_id: int,
    payload: CandidaturaCreate,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
    current_user: Usuario = Depends(get_current_user),
):
    if current_user.tipo != TipoUsuario.PRESTADOR:
        raise HTTPException(
            status_code=403,
            detail="Apenas prestadores podem se candidatar",
        )
    try:
        return candidatar(
            db, demanda_id, current_user.id, payload, publisher
        )
    except DemandaInvalidaError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except PrestadorNaoAprovadoError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    except CandidaturaDuplicadaError as exc:
        raise HTTPException(status_code=409, detail=str(exc))


@router.get(
    "/demandas/{demanda_id}/candidaturas",
    response_model=list[CandidaturaResponse],
)
def listar_candidaturas_da_demanda(
    demanda_id: int,
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    demanda = demandas_repository.get_by_id(db, demanda_id)
    if not demanda:
        raise HTTPException(status_code=404, detail="Demanda nao encontrada")
    if demanda.cliente_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Apenas o cliente da demanda pode listar as candidaturas",
        )
    return listar_da_demanda(db, demanda_id)


@router.post(
    "/candidaturas/{candidatura_id}/aceitar",
    response_model=CandidaturaResponse,
)
def aceitar(
    candidatura_id: int,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
    current_user: Usuario = Depends(get_current_user),
):
    try:
        return aceitar_candidatura(
            db, candidatura_id, current_user.id, publisher
        )
    except CandidaturaNaoEncontradaError:
        raise HTTPException(status_code=404, detail="Candidatura nao encontrada")
    except DemandaInvalidaError as exc:
        raise HTTPException(status_code=409, detail=str(exc))
    except OperacaoNaoPermitidaError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    except EstadoInvalidoError as exc:
        raise HTTPException(status_code=409, detail=str(exc))


@router.delete(
    "/candidaturas/{candidatura_id}", response_model=CandidaturaResponse
)
def cancelar(
    candidatura_id: int,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
    current_user: Usuario = Depends(get_current_user),
):
    try:
        return cancelar_candidatura(
            db, candidatura_id, current_user.id, publisher
        )
    except CandidaturaNaoEncontradaError:
        raise HTTPException(status_code=404, detail="Candidatura nao encontrada")
    except OperacaoNaoPermitidaError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    except EstadoInvalidoError as exc:
        raise HTTPException(status_code=409, detail=str(exc))


@router.get(
    "/prestadores/me/candidaturas",
    response_model=list[CandidaturaResponse],
)
def minhas_candidaturas(
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    if current_user.tipo != TipoUsuario.PRESTADOR:
        raise HTTPException(
            status_code=403,
            detail="Apenas prestadores possuem candidaturas",
        )
    return listar_minhas(db, current_user.id)
