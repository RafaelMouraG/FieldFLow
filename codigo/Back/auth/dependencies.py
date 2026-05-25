from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import InvalidTokenError
from sqlalchemy.orm import Session

from auth.security import decode_access_token
from core.database import get_db
from usuarios.infrastructure.database import repository as usuarios_repository
from usuarios.infrastructure.database.models import Usuario

bearer_scheme = HTTPBearer(auto_error=True)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> Usuario:
    credenciais_invalidas = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Credenciais invalidas",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_access_token(credentials.credentials)
        usuario_id = payload.get("sub")
        if usuario_id is None:
            raise credenciais_invalidas
    except InvalidTokenError:
        raise credenciais_invalidas

    usuario = usuarios_repository.get_by_id(db, int(usuario_id))
    if not usuario or not usuario.ativo:
        raise credenciais_invalidas
    return usuario
