from enum import Enum


class TipoUsuario(str, Enum):
    CLIENTE = "CLIENTE"
    PRESTADOR = "PRESTADOR"


class TipoDocumento(str, Enum):
    CPF = "CPF"
    CNPJ = "CNPJ"
