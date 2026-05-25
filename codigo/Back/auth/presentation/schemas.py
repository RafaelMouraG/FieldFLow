from pydantic import BaseModel, EmailStr, Field

from usuarios.presentation.schemas import UsuarioCreate, UsuarioResponse


class RegisterRequest(UsuarioCreate):
    pass


class LoginRequest(BaseModel):
    email: EmailStr
    senha: str = Field(min_length=6, max_length=128)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class RegisterResponse(BaseModel):
    usuario: UsuarioResponse
    token: TokenResponse


class SenhaUpdateRequest(BaseModel):
    senha_atual: str = Field(min_length=6, max_length=128)
    senha_nova: str = Field(min_length=6, max_length=128)
