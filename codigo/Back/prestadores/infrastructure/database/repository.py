from sqlalchemy.orm import Session

from prestadores.infrastructure.database.models import PerfilPrestador


def get_by_usuario_id(db: Session, usuario_id: int) -> PerfilPrestador | None:
    return (
        db.query(PerfilPrestador)
        .filter(PerfilPrestador.usuario_id == usuario_id)
        .first()
    )


def save(db: Session, perfil: PerfilPrestador) -> PerfilPrestador:
    # Sem commit: unidade de trabalho controlada pelo use case / get_db.
    db.add(perfil)
    db.flush()
    db.refresh(perfil)
    return perfil
