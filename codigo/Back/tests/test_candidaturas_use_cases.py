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


def test_aceitar_candidatura_e_atomico_se_save_demanda_falha(
    db, publisher, cliente, prestador_aprovado, monkeypatch
):
    """Falha entre os dois saves nao pode deixar candidatura ACEITA
    com demanda ainda PENDENTE. Bug #2: atomicidade."""
    demanda = create_demanda(db, _demanda_payload(), cliente.id, publisher)
    c1 = candidatar(
        db,
        demanda.id,
        prestador_aprovado.id,
        _candidatura_payload(1500.0),
        publisher,
    )

    # Simula falha no save da demanda — apos a candidatura ja ter sido
    # marcada como ACEITA na sessao.
    from demandas.infrastructure.database import repository as demandas_repo

    def boom(*args, **kwargs):
        raise RuntimeError("falha simulada no save da demanda")

    monkeypatch.setattr(demandas_repo, "save", boom)

    publisher.events.clear()
    with pytest.raises(RuntimeError):
        aceitar_candidatura(db, c1.id, cliente.id, publisher)

    # Safety net que o get_db faria em producao: rollback de qualquer flush
    # pendente. Depois verificamos o estado em uma nova sessao
    # (mesma engine in-memory via StaticPool).
    db.rollback()

    from sqlalchemy.orm import sessionmaker

    SessionLocal = sessionmaker(bind=db.get_bind(), autoflush=False)
    nova = SessionLocal()
    try:
        c1_recarregada = nova.query(type(c1)).filter_by(id=c1.id).first()
        demanda_recarregada = (
            nova.query(type(demanda)).filter_by(id=demanda.id).first()
        )
        assert c1_recarregada.status == StatusCandidatura.PENDENTE
        assert demanda_recarregada.status == DemandaStatus.PENDENTE
        assert demanda_recarregada.prestador_id is None
    finally:
        nova.close()

    # Nenhum evento deve ter sido publicado (publish so acontece pos-commit).
    assert publisher.events == []
