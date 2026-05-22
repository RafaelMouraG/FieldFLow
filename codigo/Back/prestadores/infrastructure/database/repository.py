from sqlalchemy.orm import Session

from prestadores.infrastructure.database.models import PerfilPrestador


def get_by_usuario_id(db: Session, usuario_id: int) -> PerfilPrestador | None:
    return (
        db.query(PerfilPrestador)
        .filter(PerfilPrestador.usuario_id == usuario_id)
        .first()
    )


def save(db: Session, perfil: PerfilPrestador) -> PerfilPrestador:
    db.add(perfil)
    db.commit()
    db.refresh(perfil)
    return perfil
