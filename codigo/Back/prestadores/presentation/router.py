from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user
from core.database import get_db
from mom.dependencies import get_event_publisher
from mom.interface import EventPublisher
from prestadores.application.use_cases import enviar_perfil, get_perfil
from prestadores.presentation.schemas import PerfilResponse, PerfilSubmit
from usuarios.domain.entities import TipoUsuario
from usuarios.infrastructure.database.models import Usuario

router = APIRouter(prefix="/prestadores", tags=["prestadores"])


@router.post("/me/perfil", response_model=PerfilResponse)
def enviar_meu_perfil(
    payload: PerfilSubmit,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
    current_user: Usuario = Depends(get_current_user),
):
    if current_user.tipo != TipoUsuario.PRESTADOR:
        raise HTTPException(
            status_code=403, detail="Apenas prestadores podem enviar perfil"
        )
    return enviar_perfil(db, current_user.id, payload, publisher)


@router.get("/me/perfil", response_model=PerfilResponse)
def meu_perfil(
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    if current_user.tipo != TipoUsuario.PRESTADOR:
        raise HTTPException(
            status_code=403, detail="Apenas prestadores possuem perfil"
        )
    perfil = get_perfil(db, current_user.id)
    if not perfil:
        raise HTTPException(status_code=404, detail="Perfil nao encontrado")
    return perfil


@router.get("/{usuario_id}/perfil", response_model=PerfilResponse)
def perfil_publico(usuario_id: int, db: Session = Depends(get_db)):
    perfil = get_perfil(db, usuario_id)
    if not perfil:
        raise HTTPException(status_code=404, detail="Perfil nao encontrado")
    return perfil
