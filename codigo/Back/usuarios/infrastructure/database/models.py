from sqlalchemy import Boolean, Column, Enum as SqlEnum, Integer, String

from core.database import Base
from usuarios.domain.entities import TipoUsuario


class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String, nullable=False)
    email = Column(String, nullable=False, unique=True, index=True)
    telefone = Column(String, nullable=True)
    tipo = Column(
        SqlEnum(TipoUsuario, name="tipo_usuario"),
        nullable=False,
    )
    ativo = Column(Boolean, nullable=False, default=True)
