from sqlalchemy.orm import Session

from mom.interface import EventPublisher
from usuarios.infrastructure.database import repository
from usuarios.infrastructure.database.models import Usuario
from usuarios.presentation.schemas import UsuarioCreate, UsuarioUpdate


def create_usuario(
    db: Session, payload: UsuarioCreate, publisher: EventPublisher
) -> Usuario:
    usuario = Usuario(**payload.model_dump())
    saved = repository.save(db, usuario)
    publisher.publish(
        "usuario.criado",
        {
            "id": saved.id,
            "nome": saved.nome,
            "email": saved.email,
            "tipo": saved.tipo.value,
        },
    )
    return saved


def list_usuarios(db: Session) -> list[Usuario]:
    return repository.get_all(db)


def get_usuario(db: Session, usuario_id: int) -> Usuario | None:
    return repository.get_by_id(db, usuario_id)


def get_usuario_por_email(db: Session, email: str) -> Usuario | None:
    return repository.get_by_email(db, email)


def update_usuario(
    db: Session,
    usuario_id: int,
    payload: UsuarioUpdate,
    publisher: EventPublisher,
) -> Usuario | None:
    usuario = repository.get_by_id(db, usuario_id)
    if not usuario:
        return None
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(usuario, key, value)
    saved = repository.save(db, usuario)
    publisher.publish(
        "usuario.atualizado",
        {"id": saved.id, "email": saved.email, "tipo": saved.tipo.value},
    )
    return saved


def delete_usuario(
    db: Session, usuario_id: int, publisher: EventPublisher
) -> bool:
    usuario = repository.get_by_id(db, usuario_id)
    if not usuario:
        return False
    repository.delete(db, usuario)
    publisher.publish("usuario.removido", {"id": usuario_id})
    return True
