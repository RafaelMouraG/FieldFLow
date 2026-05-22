from enum import Enum


class DemandaStatus(str, Enum):
    PENDENTE = "PENDENTE"
    ACEITO = "ACEITO"
    EM_EXECUCAO = "EM_EXECUCAO"
    CONCLUIDO = "CONCLUIDO"


class UnidadePagamento(str, Enum):
    FIXO = "FIXO"
    POR_DIA = "POR_DIA"
    POR_HORA = "POR_HORA"
    POR_HECTARE = "POR_HECTARE"
    A_COMBINAR = "A_COMBINAR"
