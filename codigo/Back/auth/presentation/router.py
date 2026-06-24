from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.application.use_cases import (
    CredenciaisInvalidasError,
    EmailJaCadastradoError,
    authenticate,
    change_password,
    register,
)
from auth.dependencies import get_current_user
from auth.presentation.schemas import (
    LoginRequest,
    RegisterRequest,
    RegisterResponse,
    SenhaUpdateRequest,
    TokenResponse,
)
from core.database import get_db
from mom.dependencies import get_event_publisher
from mom.interface import EventPublisher
from usuarios.application.use_cases import DocumentoJaCadastradoError
from usuarios.infrastructure.database.models import Usuario
from usuarios.presentation.schemas import UsuarioResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED
)
def registrar(
    payload: RegisterRequest,
    db: Session = Depends(get_db),
    publisher: EventPublisher = Depends(get_event_publisher),
):
    try:
        usuario, token = register(db, payload, publisher)
    except EmailJaCadastradoError:
        raise HTTPException(status_code=409, detail="Email ja cadastrado")
    except DocumentoJaCadastradoError:
        raise HTTPException(status_code=409, detail="Documento ja cadastrado")
    return RegisterResponse(
        usuario=UsuarioResponse.model_validate(usuario),
        token=TokenResponse(access_token=token),
    )


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    try:
        _, token = authenticate(db, payload.email, payload.senha)
    except CredenciaisInvalidasError:
        raise HTTPException(status_code=401, detail="Credenciais invalidas")
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UsuarioResponse)
def me(current_user: Usuario = Depends(get_current_user)):
    return current_user


@router.put("/me/senha", status_code=status.HTTP_204_NO_CONTENT)
def trocar_senha(
    payload: SenhaUpdateRequest,
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):
    change_password(db, current_user, payload.senha_nova)
