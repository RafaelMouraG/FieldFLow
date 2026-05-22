from sqlalchemy.orm import Session

from candidaturas.domain.entities import StatusCandidatura
from candidaturas.infrastructure.database import repository
from candidaturas.infrastructure.database.models import Candidatura
from candidaturas.presentation.schemas import CandidaturaCreate
from demandas.domain.entities import DemandaStatus
from demandas.infrastructure.database import repository as demandas_repository
from mom.interface import EventPublisher
from prestadores.domain.entities import StatusPerfil
from prestadores.infrastructure.database import (
    repository as prestadores_repository,
)


class DemandaInvalidaError(Exception):
    """Demanda nao existe ou nao aceita mais candidaturas."""


class PrestadorNaoAprovadoError(Exception):
    """Prestador nao possui perfil APROVADO."""


class CandidaturaDuplicadaError(Exception):
    """Prestador ja se candidatou a esta demanda."""


class CandidaturaNaoEncontradaError(Exception):
    pass


class OperacaoNaoPermitidaError(Exception):
    """Usuario nao tem permissao para a operacao."""


class EstadoInvalidoError(Exception):
    """Candidatura nao esta em PENDENTE para a operacao desejada."""


def _payload(c: Candidatura) -> dict:
    return {
        "id": c.id,
        "demanda_id": c.demanda_id,
        "prestador_id": c.prestador_id,
        "valor_proposto": c.valor_proposto,
        "status": c.status.value,
    }


def candidatar(
    db: Session,
    demanda_id: int,
    prestador_id: int,
    payload: CandidaturaCreate,
    publisher: EventPublisher,
) -> Candidatura:
    demanda = demandas_repository.get_by_id(db, demanda_id)
    if not demanda:
        raise DemandaInvalidaError("Demanda nao encontrada")
    if demanda.status != DemandaStatus.PENDENTE:
        raise DemandaInvalidaError(
            "Demanda nao aceita mais candidaturas (status atual: "
            f"{demanda.status.value})"
        )

    perfil = prestadores_repository.get_by_usuario_id(db, prestador_id)
    if not perfil or perfil.status != StatusPerfil.APROVADO:
        raise PrestadorNaoAprovadoError(
            "Prestador precisa ter perfil APROVADO para se candidatar"
        )

    if repository.get_by_demanda_e_prestador(db, demanda_id, prestador_id):
        raise CandidaturaDuplicadaError(
            "Voce ja se candidatou a esta demanda"
        )

    candidatura = Candidatura(
        demanda_id=demanda_id,
        prestador_id=prestador_id,
        mensagem=payload.mensagem,
        valor_proposto=payload.valor_proposto,
        status=StatusCandidatura.PENDENTE,
    )
    saved = repository.save(db, candidatura)
    publisher.publish("candidatura.criada", _payload(saved))
    return saved


def aceitar_candidatura(
    db: Session,
    candidatura_id: int,
    cliente_id: int,
    publisher: EventPublisher,
) -> Candidatura:
    candidatura = repository.get_by_id(db, candidatura_id)
    if not candidatura:
        raise CandidaturaNaoEncontradaError()
    if candidatura.status != StatusCandidatura.PENDENTE:
        raise EstadoInvalidoError(
            f"Candidatura esta {candidatura.status.value}"
        )

    demanda = demandas_repository.get_by_id(db, candidatura.demanda_id)
    if not demanda:
        raise DemandaInvalidaError("Demanda nao encontrada")
    if demanda.cliente_id != cliente_id:
        raise OperacaoNaoPermitidaError(
            "Apenas o cliente da demanda pode aceitar candidaturas"
        )
    if demanda.status != DemandaStatus.PENDENTE:
        raise DemandaInvalidaError(
            "Demanda nao esta mais aberta para aceite"
        )

    candidatura.status = StatusCandidatura.ACEITA
    saved = repository.save(db, candidatura)

    status_anterior = demanda.status
    demanda.status = DemandaStatus.ACEITO
    demanda.prestador_id = candidatura.prestador_id
    demandas_repository.save(db, demanda)

    publisher.publish("candidatura.aceita", _payload(saved))
    publisher.publish(
        "demanda.status.aceito",
        {
            "id": demanda.id,
            "cliente_id": demanda.cliente_id,
            "prestador_id": demanda.prestador_id,
            "titulo": demanda.titulo,
            "tipo_servico": demanda.tipo_servico,
            "valor_recompensa": demanda.valor_recompensa,
            "unidade_pagamento": demanda.unidade_pagamento.value,
            "status": demanda.status.value,
            "status_anterior": status_anterior.value,
        },
    )
    return saved


def rejeitar_outras_candidaturas(
    db: Session,
    demanda_id: int,
    aceita_id: int,
    publisher: EventPublisher,
) -> list[Candidatura]:
    """Chamado pelo worker quando uma candidatura é aceita.

    Marca todas as outras candidaturas PENDENTES da mesma demanda como
    REJEITADAS e publica `candidatura.rejeitada` para cada uma.
    """
    pendentes = repository.listar_pendentes_da_demanda(
        db, demanda_id, excluir_id=aceita_id
    )
    rejeitadas = []
    for c in pendentes:
        c.status = StatusCandidatura.REJEITADA
        repository.save(db, c)
        payload = _payload(c)
        payload["motivo"] = "outra_candidatura_aceita"
        publisher.publish("candidatura.rejeitada", payload)
        rejeitadas.append(c)
    return rejeitadas


def cancelar_candidatura(
    db: Session,
    candidatura_id: int,
    prestador_id: int,
    publisher: EventPublisher,
) -> Candidatura:
    candidatura = repository.get_by_id(db, candidatura_id)
    if not candidatura:
        raise CandidaturaNaoEncontradaError()
    if candidatura.prestador_id != prestador_id:
        raise OperacaoNaoPermitidaError(
            "Apenas o autor da candidatura pode cancela-la"
        )
    if candidatura.status != StatusCandidatura.PENDENTE:
        raise EstadoInvalidoError(
            f"Candidatura esta {candidatura.status.value}"
        )

    candidatura.status = StatusCandidatura.CANCELADA
    saved = repository.save(db, candidatura)
    publisher.publish("candidatura.cancelada", _payload(saved))
    return saved


def listar_da_demanda(db: Session, demanda_id: int) -> list[Candidatura]:
    return repository.listar_por_demanda(db, demanda_id)


def listar_minhas(db: Session, prestador_id: int) -> list[Candidatura]:
    return repository.listar_por_prestador(db, prestador_id)
