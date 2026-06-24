from sqlalchemy.orm import Session

from auth.security import create_access_token, hash_password, verify_password
from mom.interface import EventPublisher
from prestadores.application.use_cases import criar_perfil_pendente
from usuarios.application.use_cases import create_usuario
from usuarios.domain.entities import TipoUsuario
from usuarios.infrastructure.database import repository as usuarios_repository
from usuarios.infrastructure.database.models import Usuario
from usuarios.presentation.schemas import UsuarioCreate


class CredenciaisInvalidasError(Exception):
    pass


class EmailJaCadastradoError(Exception):
    pass


def register(
    db: Session, payload: UsuarioCreate, publisher: EventPublisher
) -> tuple[Usuario, str]:
    if usuarios_repository.get_by_email(db, payload.email):
        raise EmailJaCadastradoError()
    usuario = create_usuario(db, payload, publisher)
    if usuario.tipo == TipoUsuario.PRESTADOR:
        criar_perfil_pendente(db, usuario.id)
    token = _build_token(usuario)
    return usuario, token


def authenticate(db: Session, email: str, senha: str) -> tuple[Usuario, str]:
    usuario = usuarios_repository.get_by_email(db, email)
    if not usuario or not usuario.ativo:
        raise CredenciaisInvalidasError()
    if not verify_password(senha, usuario.senha_hash):
        raise CredenciaisInvalidasError()
    return usuario, _build_token(usuario)


def change_password(db: Session, usuario: Usuario, senha_nova: str) -> None:
    usuario.senha_hash = hash_password(senha_nova)
    db.add(usuario)
    db.commit()


def _build_token(usuario: Usuario) -> str:
    return create_access_token(
        subject=str(usuario.id),
        extra={"email": usuario.email, "tipo": usuario.tipo.value},
    )
