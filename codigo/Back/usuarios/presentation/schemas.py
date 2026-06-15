from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from usuarios.domain.entities import TipoDocumento, TipoUsuario


def _so_digitos(valor: str) -> str:
    return "".join(ch for ch in valor if ch.isdigit())


class UsuarioBase(BaseModel):
    nome: str
    email: EmailStr
    telefone: Optional[str] = None
    tipo_documento: TipoDocumento
    documento: str = Field(min_length=11, max_length=18)
    tipo: TipoUsuario
    # Endereco da fazenda/empresa (uso pratico apenas para clientes CNPJ).
    endereco: Optional[str] = None
    endereco_lat: Optional[float] = None
    endereco_lng: Optional[float] = None


class UsuarioCreate(UsuarioBase):
    senha: str = Field(min_length=6, max_length=128)

    @field_validator("documento")
    @classmethod
    def _normaliza_documento(cls, valor: str, info) -> str:
        tipo = info.data.get("tipo_documento")
        valor = _so_digitos(valor)
        if tipo == TipoDocumento.CPF and len(valor) != 11:
            raise ValueError("CPF deve ter 11 digitos")
        if tipo == TipoDocumento.CNPJ and len(valor) != 14:
            raise ValueError("CNPJ deve ter 14 digitos")
        return valor


class UsuarioUpdate(BaseModel):
    nome: Optional[str] = None
    email: Optional[EmailStr] = None
    telefone: Optional[str] = None
    endereco: Optional[str] = None
    endereco_lat: Optional[float] = None
    endereco_lng: Optional[float] = None
    # Campos sensiveis (senha, tipo, ativo) NAO entram aqui:
    # - senha: fluxo proprio em PUT /auth/me/senha (exige senha atual)
    # - tipo: definido no cadastro; trocar quebra invariantes (ex.: perfil prestador)
    # - ativo: desativacao via DELETE /usuarios/{id}


class UsuarioResponse(UsuarioBase):
    id: int
    ativo: bool

    model_config = ConfigDict(from_attributes=True)


class UsuarioPublicResponse(BaseModel):
    """Versao reduzida para exibir um usuario a OUTROS usuarios autenticados.

    Omite documento e telefone (dados pessoais) — o proprio usuario ve tudo
    via GET /auth/me.
    """

    id: int
    nome: str
    tipo: TipoUsuario

    model_config = ConfigDict(from_attributes=True)
