from enum import Enum


class DemandaStatus(str, Enum):
    PENDENTE = "PENDENTE"
    ACEITO = "ACEITO"
    EM_EXECUCAO = "EM_EXECUCAO"
    CONCLUIDO = "CONCLUIDO"
