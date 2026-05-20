from enum import Enum


class TipoUsuario(str, Enum):
    CLIENTE = "CLIENTE"
    PRESTADOR = "PRESTADOR"
