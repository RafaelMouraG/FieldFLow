from sqlalchemy.orm import Session

from demandas.domain.entities import DemandaStatus
from demandas.infrastructure.database import repository
from demandas.infrastructure.database.models import Demanda
from demandas.presentation.schemas import DemandaCreate
from mom.interface import EventPublisher


class TransicaoStatusInvalidaError(Exception):
    """Transicao direta para um status nao permitida via PATCH."""


class OperacaoNaoPermitidaError(Exception):
    """Usuario nao tem permissao para a operacao."""


# Transicoes permitidas via PATCH /demandas/{id}/status.
# PENDENTE -> ACEITO acontece via POST /candidaturas/{id}/aceitar.
# Cada transicao define quem pode disparar: "cliente" (dono da demanda)
# ou "prestador" (prestador atribuido).
_TRANSICOES_PERMITIDAS: dict[
    tuple[DemandaStatus, DemandaStatus], str
] = {
    (DemandaStatus.ACEITO, DemandaStatus.EM_EXECUCAO): "prestador",
    (DemandaStatus.EM_EXECUCAO, DemandaStatus.CONCLUIDO): "cliente",
}


def _demanda_payload(demanda: Demanda) -> dict:
    return {
        "id": demanda.id,
        "cliente_id": demanda.cliente_id,
        "prestador_id": demanda.prestador_id,
        "titulo": demanda.titulo,
        "tipo_servico": demanda.tipo_servico,
        "valor_recompensa": demanda.valor_recompensa,
        "unidade_pagamento": demanda.unidade_pagamento.value,
        "status": demanda.status.value,
    }


def create_demanda(
    db: Session,
    payload: DemandaCreate,
    cliente_id: int,
    publisher: EventPublisher,
) -> Demanda:
    demanda = Demanda(cliente_id=cliente_id, **payload.model_dump())
    saved = repository.save(db, demanda)
    db.commit()
    db.refresh(saved)
    publisher.publish("demanda.criada", _demanda_payload(saved))
    return saved


def list_demandas(db: Session) -> list[Demanda]:
    return repository.get_all(db)


def list_demandas_do_cliente(db: Session, cliente_id: int) -> list[Demanda]:
    return repository.get_by_cliente(db, cliente_id)


def list_demandas_pendentes(db: Session) -> list[Demanda]:
    return repository.get_pendentes(db)


def list_demandas_para_prestador(
    db: Session, prestador_id: int
) -> list[Demanda]:
    return repository.get_visiveis_para_prestador(db, prestador_id)


def get_demanda(db: Session, demanda_id: int) -> Demanda | None:
    return repository.get_by_id(db, demanda_id)


def update_demanda_status(
    db: Session,
    demanda_id: int,
    usuario_id: int,
    status: DemandaStatus,
    publisher: EventPublisher,
) -> Demanda | None:
    if status == DemandaStatus.ACEITO:
        raise TransicaoStatusInvalidaError(
            "Para aceitar uma demanda, use POST /candidaturas/{id}/aceitar"
        )

    demanda = repository.get_by_id(db, demanda_id)
    if not demanda:
        return None

    transicao = (demanda.status, status)
    ator = _TRANSICOES_PERMITIDAS.get(transicao)
    if ator is None:
        raise TransicaoStatusInvalidaError(
            f"Transicao {demanda.status.value} -> {status.value} nao permitida"
        )

    if ator == "cliente" and demanda.cliente_id != usuario_id:
        raise OperacaoNaoPermitidaError(
            "Apenas o cliente dono da demanda pode realizar esta transicao"
        )
    if ator == "prestador" and demanda.prestador_id != usuario_id:
        raise OperacaoNaoPermitidaError(
            "Apenas o prestador atribuido pode realizar esta transicao"
        )

    status_anterior = demanda.status
    demanda.status = status
    saved = repository.save(db, demanda)
    db.commit()
    db.refresh(saved)

    payload = _demanda_payload(saved)
    payload["status_anterior"] = status_anterior.value
    publisher.publish(f"demanda.status.{status.value.lower()}", payload)
    return saved


def update_demanda(
    db: Session,
    demanda_id: int,
    cliente_id: int,
    payload: DemandaCreate,
    publisher: EventPublisher,
) -> Demanda | None:
    demanda = repository.get_by_id(db, demanda_id)
    if not demanda:
        return None
    if demanda.cliente_id != cliente_id:
        raise OperacaoNaoPermitidaError(
            "Apenas o cliente dono da demanda pode edita-la"
        )
    if demanda.status != DemandaStatus.PENDENTE:
        raise TransicaoStatusInvalidaError(
            "Apenas demandas PENDENTES podem ser editadas"
        )
    for key, value in payload.model_dump().items():
        setattr(demanda, key, value)
    saved = repository.save(db, demanda)
    db.commit()
    db.refresh(saved)
    publisher.publish("demanda.atualizada", _demanda_payload(saved))
    return saved


def delete_demanda(
    db: Session,
    demanda_id: int,
    cliente_id: int,
    publisher: EventPublisher,
) -> bool:
    demanda = repository.get_by_id(db, demanda_id)
    if not demanda:
        return False
    if demanda.cliente_id != cliente_id:
        raise OperacaoNaoPermitidaError(
            "Apenas o cliente dono da demanda pode remove-la"
        )
    repository.delete(db, demanda)
    db.commit()
    publisher.publish("demanda.removida", {"id": demanda_id})
    return True
