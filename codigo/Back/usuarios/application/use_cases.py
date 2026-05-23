from sqlalchemy.orm import Session

from auth.security import hash_password
from mom.interface import EventPublisher
from usuarios.infrastructure.database import repository
from usuarios.infrastructure.database.models import Usuario
from usuarios.presentation.schemas import UsuarioCreate, UsuarioUpdate


class DocumentoJaCadastradoError(Exception):
    pass


def create_usuario(
    db: Session, payload: UsuarioCreate, publisher: EventPublisher
) -> Usuario:
    if repository.get_by_documento(db, payload.documento):
        raise DocumentoJaCadastradoError()
    data = payload.model_dump()
    senha = data.pop("senha")
    usuario = Usuario(**data, senha_hash=hash_password(senha))
    saved = repository.save(db, usuario)
    db.commit()
    db.refresh(saved)
    publisher.publish(
        "usuario.criado",
        {
            "id": saved.id,
            "nome": saved.nome,
            "email": saved.email,
            "tipo": saved.tipo.value,
            "tipo_documento": saved.tipo_documento.value,
        },
    )
    return saved


def get_usuario(db: Session, usuario_id: int) -> Usuario | None:
    return repository.get_by_id(db, usuario_id)


def update_usuario(
    db: Session,
    usuario_id: int,
    payload: UsuarioUpdate,
    publisher: EventPublisher,
) -> Usuario | None:
    usuario = repository.get_by_id(db, usuario_id)
    if not usuario:
        return None
    data = payload.model_dump(exclude_unset=True)
    if "senha" in data:
        usuario.senha_hash = hash_password(data.pop("senha"))
    for key, value in data.items():
        setattr(usuario, key, value)
    saved = repository.save(db, usuario)
    db.commit()
    db.refresh(saved)
    publisher.publish(
        "usuario.atualizado",
        {"id": saved.id, "email": saved.email, "tipo": saved.tipo.value},
    )
    return saved


def delete_usuario(
    db: Session, usuario_id: int, publisher: EventPublisher
) -> bool:
    """Soft-delete: marca o usuario como inativo.

    Hard delete bateria em FK RESTRICT se o usuario for cliente de uma
    demanda; alem disso, perderiamos o historico de candidaturas e
    notificacoes vinculadas. get_current_user ja bloqueia login de inativos.
    """
    usuario = repository.get_by_id(db, usuario_id)
    if not usuario:
        return False
    usuario.ativo = False
    repository.save(db, usuario)
    db.commit()
    publisher.publish("usuario.removido", {"id": usuario_id})
    return True
