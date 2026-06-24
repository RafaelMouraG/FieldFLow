from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user
from core.database import get_db
from notificacoes.application.use_cases import (
    listar_para_usuario,
    marcar_lidas,
)
from notificacoes.presentation.schemas import NotificacaoResponse
from usuarios.infrastructure.database.models import Usuario

router = APIRouter(prefix="/notificacoes", tags=["notificacoes"])


@router.get("", response_model=list[NotificacaoResponse])
def listar_notificacoes(
    limit: int = Query(default=100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    """Eventos relevantes para o usuario autenticado (feed escopado)."""
    return listar_para_usuario(db, current_user, limit=limit)


@router.post("/marcar-lidas", status_code=status.HTTP_204_NO_CONTENT)
def marcar_notificacoes_lidas(
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    """Marca todas as notificacoes visiveis do usuario como lidas."""
    marcar_lidas(db, current_user)
