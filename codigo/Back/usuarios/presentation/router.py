from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from core.database import get_db
from mom.dependencies import get_event_publisher
from mom.interface import EventPublisher
from usuarios.application.use_cases import (
    create_usuario,
    delete_usuario,
    get_usuario,
    get_usuario_por_email,
    list_usuarios,
    update_usuario,
)
from usuarios.presentation.schemas import (
    UsuarioCreate,
    UsuarioResponse,
    UsuarioUpdate,
)

router = APIRouter(prefix="/usuarios", tags=["usuarios"])


@router.post("", response_model=UsuarioResponse, status_code=status.HTTP_201_CREATED)
def criar_usuario(
    payload: UsuarioCreate,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
):
    if get_usuario_por_email(db, payload.email):
        raise HTTPException(status_code=409, detail="Email ja cadastrado")
    return create_usuario(db, payload, publisher)


@router.get("", response_model=list[UsuarioResponse])
def listar_usuarios(db: Session = Depends(get_db)):
    return list_usuarios(db)


@router.get("/{usuario_id}", response_model=UsuarioResponse)
def obter_usuario(usuario_id: int, db: Session = Depends(get_db)):
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
):
    usuario = update_usuario(db, usuario_id, payload, publisher)
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado")
    return usuario


@router.delete("/{usuario_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_usuario(
    usuario_id: int,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
):
    sucesso = delete_usuario(db, usuario_id, publisher)
    if not sucesso:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado")
