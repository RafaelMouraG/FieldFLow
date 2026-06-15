from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user
from avaliacoes.application.use_cases import (
    AvaliacaoDuplicadaError,
    DemandaInvalidaError,
    EstadoInvalidoError,
    NotaInvalidaError,
    OperacaoNaoPermitidaError,
    criar_avaliacao,
    get_da_demanda,
    listar_do_prestador,
)
from avaliacoes.presentation.schemas import AvaliacaoCreate, AvaliacaoResponse
from core.database import get_db
from mom.dependencies import get_event_publisher
from mom.interface import EventPublisher
from usuarios.domain.entities import TipoUsuario
from usuarios.infrastructure.database.models import Usuario

router = APIRouter(tags=["avaliacoes"])


@router.post(
    "/demandas/{demanda_id}/avaliacao",
    response_model=AvaliacaoResponse,
    status_code=status.HTTP_201_CREATED,
)
def avaliar(
    demanda_id: int,
    payload: AvaliacaoCreate,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
    current_user: Usuario = Depends(get_current_user),
):
    if current_user.tipo != TipoUsuario.CLIENTE:
        raise HTTPException(
            status_code=403, detail="Apenas clientes podem avaliar"
        )
    try:
        return criar_avaliacao(
            db,
            demanda_id,
            current_user.id,
            payload.nota,
            payload.comentario,
            publisher,
        )
    except DemandaInvalidaError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except OperacaoNaoPermitidaError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    except (EstadoInvalidoError, NotaInvalidaError) as exc:
        raise HTTPException(status_code=409, detail=str(exc))
    except AvaliacaoDuplicadaError as exc:
        raise HTTPException(status_code=409, detail=str(exc))


@router.get(
    "/demandas/{demanda_id}/avaliacao",
    response_model=AvaliacaoResponse,
)
def obter_avaliacao_da_demanda(
    demanda_id: int,
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),  # noqa: ARG001
):
    avaliacao = get_da_demanda(db, demanda_id)
    if not avaliacao:
        raise HTTPException(
            status_code=404, detail="Demanda ainda nao avaliada"
        )
    return avaliacao


@router.get(
    "/prestadores/{prestador_id}/avaliacoes",
    response_model=list[AvaliacaoResponse],
)
def listar_avaliacoes(
    prestador_id: int,
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),  # noqa: ARG001
):
    return listar_do_prestador(db, prestador_id)
