import pytest

from candidaturas.application.use_cases import (
    OperacaoNaoPermitidaError,
    PrestadorNaoAprovadoError,
    aceitar_candidatura,
    candidatar,
    rejeitar_outras_candidaturas,
)
from candidaturas.domain.entities import StatusCandidatura
from candidaturas.presentation.schemas import CandidaturaCreate
from demandas.application.use_cases import create_demanda
from demandas.domain.entities import DemandaStatus, UnidadePagamento
from demandas.presentation.schemas import DemandaCreate


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


def _candidatura_payload(valor: float) -> CandidaturaCreate:
    return CandidaturaCreate(mensagem="Posso atender", valor_proposto=valor)


def test_candidatar_falha_se_prestador_nao_tem_perfil(
    db, publisher, cliente
):
    """Cliente nao pode se candidatar (nao tem perfil aprovado)."""
    demanda = create_demanda(db, _demanda_payload(), cliente.id, publisher)

    with pytest.raises(PrestadorNaoAprovadoError):
        candidatar(
            db, demanda.id, cliente.id, _candidatura_payload(1000.0), publisher
        )


def test_fluxo_aceite_marca_demanda_e_publica_eventos(
    db, publisher, cliente, prestador_aprovado, outro_prestador_aprovado
):
    demanda = create_demanda(db, _demanda_payload(), cliente.id, publisher)

    c1 = candidatar(
        db,
        demanda.id,
        prestador_aprovado.id,
        _candidatura_payload(1500.0),
        publisher,
    )
    c2 = candidatar(
        db,
        demanda.id,
        outro_prestador_aprovado.id,
        _candidatura_payload(1800.0),
        publisher,
    )

    aceitar_candidatura(db, c1.id, cliente.id, publisher)

    db.refresh(demanda)
    assert demanda.status == DemandaStatus.ACEITO
    assert demanda.prestador_id == prestador_aprovado.id
    db.refresh(c1)
    assert c1.status == StatusCandidatura.ACEITA

    # Worker executa a rejeicao em cascata:
    rejeitar_outras_candidaturas(db, demanda.id, c1.id, publisher)
    db.refresh(c2)
    assert c2.status == StatusCandidatura.REJEITADA

    rks = publisher.routing_keys()
    assert "demanda.criada" in rks
    assert rks.count("candidatura.criada") == 2
    assert "candidatura.aceita" in rks
    assert "demanda.status.aceito" in rks
    assert "candidatura.rejeitada" in rks


def test_aceitar_falha_se_nao_for_dono_da_demanda(
    db, publisher, cliente, prestador_aprovado, outro_prestador_aprovado
):
    demanda = create_demanda(db, _demanda_payload(), cliente.id, publisher)
    c1 = candidatar(
        db,
        demanda.id,
        prestador_aprovado.id,
        _candidatura_payload(1500.0),
        publisher,
    )

    with pytest.raises(OperacaoNaoPermitidaError):
        aceitar_candidatura(
            db, c1.id, outro_prestador_aprovado.id, publisher
        )
