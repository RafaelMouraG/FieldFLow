from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr

from usuarios.domain.entities import TipoUsuario


class UsuarioBase(BaseModel):
    nome: str
    email: EmailStr
    telefone: Optional[str] = None
    tipo: TipoUsuario


class UsuarioCreate(UsuarioBase):
    pass


class UsuarioUpdate(BaseModel):
    nome: Optional[str] = None
    email: Optional[EmailStr] = None
    telefone: Optional[str] = None
    tipo: Optional[TipoUsuario] = None
    ativo: Optional[bool] = None


class UsuarioResponse(UsuarioBase):
    id: int
    ativo: bool

    model_config = ConfigDict(from_attributes=True)
