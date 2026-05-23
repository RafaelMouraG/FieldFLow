from candidaturas.application.use_cases import (
    aceitar_candidatura,
    candidatar,
)
from candidaturas.presentation.schemas import CandidaturaCreate
from demandas.application.use_cases import (
    OperacaoNaoPermitidaError,
    TransicaoStatusInvalidaError,
    create_demanda,
    delete_demanda,
    list_demandas_para_prestador,
    update_demanda,
    update_demanda_status,
)
from demandas.domain.entities import DemandaStatus, UnidadePagamento
from demandas.presentation.schemas import DemandaCreate

import pytest


def _payload() -> DemandaCreate:
    return DemandaCreate(
        titulo="Pulverizacao soja",
        descricao="Talhao 3",
        origem="Fazenda Boa Vista",
        area_hectares=12.5,
        valor_recompensa=1500.0,
        unidade_pagamento=UnidadePagamento.FIXO,
        tipo_servico="PULVERIZACAO",
    )


def test_create_demanda_publica_evento(db, publisher, cliente):
    demanda = create_demanda(db, _payload(), cliente.id, publisher)

    assert demanda.id is not None
    assert demanda.cliente_id == cliente.id
    assert publisher.routing_keys() == ["demanda.criada"]
    evento_type, evento_payload, evento_id = publisher.events[0]
    assert evento_payload["cliente_id"] == cliente.id
    assert evento_payload["event_id"] == evento_id


def test_update_demanda_falha_se_outro_cliente(
    db, publisher, cliente, outro_prestador_aprovado
):
    demanda = create_demanda(db, _payload(), cliente.id, publisher)

    with pytest.raises(OperacaoNaoPermitidaError):
        update_demanda(
            db, demanda.id, outro_prestador_aprovado.id, _payload(), publisher
        )


def test_delete_demanda_falha_se_outro_cliente(db, publisher, cliente):
    demanda = create_demanda(db, _payload(), cliente.id, publisher)

    with pytest.raises(OperacaoNaoPermitidaError):
        delete_demanda(db, demanda.id, cliente.id + 999, publisher)


def _aceitar_via_candidatura(db, publisher, cliente, prestador):
    """Cria demanda, candidatura e aceita — devolve a demanda em ACEITO."""
    demanda = create_demanda(db, _payload(), cliente.id, publisher)
    candidatura = candidatar(
        db,
        demanda.id,
        prestador.id,
        CandidaturaCreate(mensagem="oi", valor_proposto=1500.0),
        publisher,
    )
    aceitar_candidatura(db, candidatura.id, cliente.id, publisher)
    db.refresh(demanda)
    return demanda


def test_prestador_atribuido_inicia_execucao(
    db, publisher, cliente, prestador_aprovado
):
    demanda = _aceitar_via_candidatura(
        db, publisher, cliente, prestador_aprovado
    )

    atualizada = update_demanda_status(
        db,
        demanda.id,
        prestador_aprovado.id,
        DemandaStatus.EM_EXECUCAO,
        publisher,
    )

    assert atualizada.status == DemandaStatus.EM_EXECUCAO
    assert "demanda.status.em_execucao" in publisher.routing_keys()


def test_prestador_nao_atribuido_nao_pode_iniciar_execucao(
    db, publisher, cliente, prestador_aprovado, outro_prestador_aprovado
):
    demanda = _aceitar_via_candidatura(
        db, publisher, cliente, prestador_aprovado
    )

    with pytest.raises(OperacaoNaoPermitidaError):
        update_demanda_status(
            db,
            demanda.id,
            outro_prestador_aprovado.id,
            DemandaStatus.EM_EXECUCAO,
            publisher,
        )


def test_cliente_nao_pode_iniciar_execucao(
    db, publisher, cliente, prestador_aprovado
):
    demanda = _aceitar_via_candidatura(
        db, publisher, cliente, prestador_aprovado
    )

    with pytest.raises(OperacaoNaoPermitidaError):
        update_demanda_status(
            db,
            demanda.id,
            cliente.id,
            DemandaStatus.EM_EXECUCAO,
            publisher,
        )


def test_cliente_conclui_demanda_em_execucao(
    db, publisher, cliente, prestador_aprovado
):
    demanda = _aceitar_via_candidatura(
        db, publisher, cliente, prestador_aprovado
    )
    update_demanda_status(
        db,
        demanda.id,
        prestador_aprovado.id,
        DemandaStatus.EM_EXECUCAO,
        publisher,
    )

    concluida = update_demanda_status(
        db,
        demanda.id,
        cliente.id,
        DemandaStatus.CONCLUIDO,
        publisher,
    )

    assert concluida.status == DemandaStatus.CONCLUIDO
    assert "demanda.status.concluido" in publisher.routing_keys()


def test_prestador_nao_pode_concluir_demanda(
    db, publisher, cliente, prestador_aprovado
):
    demanda = _aceitar_via_candidatura(
        db, publisher, cliente, prestador_aprovado
    )
    update_demanda_status(
        db,
        demanda.id,
        prestador_aprovado.id,
        DemandaStatus.EM_EXECUCAO,
        publisher,
    )

    with pytest.raises(OperacaoNaoPermitidaError):
        update_demanda_status(
            db,
            demanda.id,
            prestador_aprovado.id,
            DemandaStatus.CONCLUIDO,
            publisher,
        )


def test_transicao_invalida_pendente_para_em_execucao(
    db, publisher, cliente, prestador_aprovado
):
    demanda = create_demanda(db, _payload(), cliente.id, publisher)

    with pytest.raises(TransicaoStatusInvalidaError):
        update_demanda_status(
            db,
            demanda.id,
            prestador_aprovado.id,
            DemandaStatus.EM_EXECUCAO,
            publisher,
        )


def test_transicao_invalida_aceito_para_concluido(
    db, publisher, cliente, prestador_aprovado
):
    demanda = _aceitar_via_candidatura(
        db, publisher, cliente, prestador_aprovado
    )

    with pytest.raises(TransicaoStatusInvalidaError):
        update_demanda_status(
            db,
            demanda.id,
            cliente.id,
            DemandaStatus.CONCLUIDO,
            publisher,
        )


def test_patch_para_aceito_continua_bloqueado(db, publisher, cliente):
    demanda = create_demanda(db, _payload(), cliente.id, publisher)

    with pytest.raises(TransicaoStatusInvalidaError):
        update_demanda_status(
            db,
            demanda.id,
            cliente.id,
            DemandaStatus.ACEITO,
            publisher,
        )


def test_prestador_ve_demandas_pendentes_e_suas_atribuidas(
    db, publisher, cliente, prestador_aprovado, outro_prestador_aprovado
):
    atribuida = _aceitar_via_candidatura(
        db, publisher, cliente, prestador_aprovado
    )
    outra_pendente = create_demanda(db, _payload(), cliente.id, publisher)

    visiveis = list_demandas_para_prestador(db, prestador_aprovado.id)
    ids = {d.id for d in visiveis}

    assert atribuida.id in ids
    assert outra_pendente.id in ids

    visiveis_outro = list_demandas_para_prestador(
        db, outro_prestador_aprovado.id
    )
    ids_outro = {d.id for d in visiveis_outro}
    assert atribuida.id not in ids_outro
    assert outra_pendente.id in ids_outro
