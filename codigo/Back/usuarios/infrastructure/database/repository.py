from sqlalchemy.orm import Session

from usuarios.infrastructure.database.models import Usuario


def get_by_id(db: Session, usuario_id: int) -> Usuario | None:
    return db.query(Usuario).filter(Usuario.id == usuario_id).first()


def get_by_email(db: Session, email: str) -> Usuario | None:
    return db.query(Usuario).filter(Usuario.email == email).first()


def get_all(db: Session) -> list[Usuario]:
    return db.query(Usuario).order_by(Usuario.id).all()


def save(db: Session, usuario: Usuario) -> Usuario:
    db.add(usuario)
    db.commit()
    db.refresh(usuario)
    return usuario


def delete(db: Session, usuario: Usuario) -> None:
    db.delete(usuario)
    db.commit()
