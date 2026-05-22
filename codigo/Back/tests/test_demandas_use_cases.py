from demandas.application.use_cases import (
    OperacaoNaoPermitidaError,
    create_demanda,
    delete_demanda,
    update_demanda,
)
from demandas.domain.entities import UnidadePagamento
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
