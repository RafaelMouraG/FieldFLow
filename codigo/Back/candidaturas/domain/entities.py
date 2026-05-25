from enum import Enum


class StatusCandidatura(str, Enum):
    PENDENTE = "PENDENTE"
    ACEITA = "ACEITA"
    REJEITADA = "REJEITADA"
    CANCELADA = "CANCELADA"
