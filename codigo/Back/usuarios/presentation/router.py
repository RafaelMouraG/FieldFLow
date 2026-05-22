from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user
from core.database import get_db
from mom.dependencies import get_event_publisher
from mom.interface import EventPublisher
from usuarios.application.use_cases import (
    delete_usuario,
    get_usuario,
    update_usuario,
)
from usuarios.infrastructure.database.models import Usuario
from usuarios.presentation.schemas import (
    UsuarioPublicResponse,
    UsuarioResponse,
    UsuarioUpdate,
)

router = APIRouter(prefix="/usuarios", tags=["usuarios"])


@router.get("/{usuario_id}", response_model=UsuarioPublicResponse)
def obter_usuario(
    usuario_id: int,
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),  # noqa: ARG001
):
    usuario = get_usuario(db, usuario_id)
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado")
    return usuario


@router.put("/{usuario_id}", response_model=UsuarioResponse)
def atualizar_usuario(
    usuario_id: int,
    payload: UsuarioUpdate,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
    current_user: Usuario = Depends(get_current_user),
):
    if current_user.id != usuario_id:
        raise HTTPException(
            status_code=403,
            detail="Voce so pode editar o proprio usuario",
        )
    usuario = update_usuario(db, usuario_id, payload, publisher)
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado")
    return usuario


@router.delete("/{usuario_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_usuario(
    usuario_id: int,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
    current_user: Usuario = Depends(get_current_user),
):
    if current_user.id != usuario_id:
        raise HTTPException(
            status_code=403,
            detail="Voce so pode remover o proprio usuario",
        )
    sucesso = delete_usuario(db, usuario_id, publisher)
    if not sucesso:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado")
