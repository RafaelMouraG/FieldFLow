from enum import Enum


class StatusPerfil(str, Enum):
    INCOMPLETO = "INCOMPLETO"
    EM_ANALISE = "EM_ANALISE"
    APROVADO = "APROVADO"
    REPROVADO = "REPROVADO"
