"""Testes dos handlers do worker de email.

Verificam que o destinatario correto e resolvido (cliente vs prestador) a partir
dos ids do payload e que a idempotencia (dedup por event_id) evita reenvio.
"""
from candidaturas.application.use_cases import candidatar
from candidaturas.presentation.schemas import CandidaturaCreate
from demandas.application.use_cases import create_demanda
from demandas.domain.entities import UnidadePagamento
from demandas.presentation.schemas import DemandaCreate
from emails.infrastructure.database import repository as emails_repository
from worker.email_handlers import (
    notificar_candidatura_aceita,
    notificar_candidatura_criada,
)


def _demanda_payload() -> DemandaCreate:
    return DemandaCreate(
        titulo="Plantio milho",
        descricao="Talhao 5",
        origem="Fazenda Sao Joao",
        area_hectares=20.0,
        valor_recompensa=2500.0,
        unidade_pagamento=UnidadePagamento.FIXO,
        tipo_servico="PLANTIO",
    )


def _criar_candidatura(db, publisher, cliente, prestador):
    demanda = create_demanda(db, _demanda_payload(), cliente.id, publisher)
    candidatura = candidatar(
        db,
        demanda.id,
        prestador.id,
        CandidaturaCreate(mensagem="Posso atender", valor_proposto=1500.0),
        publisher,
    )
    return demanda, candidatura


def test_candidatura_criada_notifica_o_cliente(
    db, publisher, notifier, cliente, prestador_aprovado
):
    demanda, candidatura = _criar_candidatura(
        db, publisher, cliente, prestador_aprovado
    )
    payload = {"demanda_id": demanda.id, "prestador_id": prestador_aprovado.id}

    notificar_candidatura_criada(db, payload, "evt-1", notifier)

    # Email vai para o CLIENTE dono da demanda, nao para o prestador.
    assert notifier.recipients() == [cliente.email]
    to, subject, body = notifier.sent[0]
    assert demanda.titulo in subject
    assert prestador_aprovado.nome in body
    # Auditoria gravada (flush) com o event_id.
    assert emails_repository.get_by_event_id(db, "evt-1") is not None


def test_candidatura_aceita_notifica_o_prestador(
    db, publisher, notifier, cliente, prestador_aprovado
):
    demanda, _ = _criar_candidatura(db, publisher, cliente, prestador_aprovado)
    payload = {"demanda_id": demanda.id, "prestador_id": prestador_aprovado.id}

    notificar_candidatura_aceita(db, payload, "evt-2", notifier)

    # Email vai para o PRESTADOR escolhido.
    assert notifier.recipients() == [prestador_aprovado.email]
    registro = emails_repository.get_by_event_id(db, "evt-2")
    assert registro is not None
    assert registro.destinatario == prestador_aprovado.email


def test_idempotencia_nao_reenvia_para_mesmo_event_id(
    db, publisher, notifier, cliente, prestador_aprovado
):
    """Replica a barreira de dedup do consumer: se ja existe registro para o
    event_id, o email nao e reenviado."""
    demanda, _ = _criar_candidatura(db, publisher, cliente, prestador_aprovado)
    payload = {"demanda_id": demanda.id, "prestador_id": prestador_aprovado.id}

    notificar_candidatura_aceita(db, payload, "evt-dup", notifier)

    # 2a entrega do mesmo event_id: o consumer pularia via get_by_event_id.
    if emails_repository.get_by_event_id(db, "evt-dup") is None:
        notificar_candidatura_aceita(db, payload, "evt-dup", notifier)

    assert len(notifier.sent) == 1


def test_destinatario_invalido_nao_envia_nem_grava(
    db, publisher, notifier, cliente, prestador_aprovado
):
    """Payload sem ids nao deve enviar email nem gravar auditoria."""
    notificar_candidatura_criada(db, {}, "evt-vazio", notifier)

    assert notifier.sent == []
    assert emails_repository.get_by_event_id(db, "evt-vazio") is None
