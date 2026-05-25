from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from core.database import get_db
from notificacoes.infrastructure.database import repository
from notificacoes.presentation.schemas import NotificacaoResponse

router = APIRouter(prefix="/notificacoes", tags=["notificacoes"])


@router.get("", response_model=list[NotificacaoResponse])
def listar_notificacoes(
    limit: int = Query(default=100, ge=1, le=500),
    db: Session = Depends(get_db),
):
    return repository.get_all(db, limit=limit)
