from sqlalchemy.orm import Session

from avaliacoes.domain.entities import NOTA_MAX, NOTA_MIN
from avaliacoes.infrastructure.database import repository
from avaliacoes.infrastructure.database.models import Avaliacao
from demandas.domain.entities import DemandaStatus
from demandas.infrastructure.database import repository as demandas_repository
from mom.interface import EventPublisher


class DemandaInvalidaError(Exception):
    """Demanda nao existe."""


class OperacaoNaoPermitidaError(Exception):
    """Usuario nao e o cliente dono da demanda."""


class EstadoInvalidoError(Exception):
    """Demanda nao esta CONCLUIDA ou nao tem prestador atribuido."""


class NotaInvalidaError(Exception):
    """Nota fora do intervalo permitido."""


class AvaliacaoDuplicadaError(Exception):
    """Demanda ja foi avaliada."""


def _payload(a: Avaliacao) -> dict:
    return {
        "id": a.id,
        "demanda_id": a.demanda_id,
        "autor_id": a.autor_id,
        "prestador_id": a.prestador_id,
        "nota": a.nota,
    }


def criar_avaliacao(
    db: Session,
    demanda_id: int,
    autor_id: int,
    nota: int,
    comentario: str | None,
    publisher: EventPublisher,
) -> Avaliacao:
    if nota < NOTA_MIN or nota > NOTA_MAX:
        raise NotaInvalidaError(f"A nota deve estar entre {NOTA_MIN} e {NOTA_MAX}")

    demanda = demandas_repository.get_by_id(db, demanda_id)
    if not demanda:
        raise DemandaInvalidaError("Demanda nao encontrada")
    if demanda.cliente_id != autor_id:
        raise OperacaoNaoPermitidaError(
            "Apenas o cliente dono da demanda pode avaliar"
        )
    if demanda.status != DemandaStatus.CONCLUIDO:
        raise EstadoInvalidoError(
            "So e possivel avaliar apos a demanda ser concluida"
        )
    if demanda.prestador_id is None:
        raise EstadoInvalidoError("A demanda nao tem prestador atribuido")
    if repository.get_by_demanda(db, demanda_id):
        raise AvaliacaoDuplicadaError("Esta demanda ja foi avaliada")

    avaliacao = Avaliacao(
        demanda_id=demanda_id,
        autor_id=autor_id,
        prestador_id=demanda.prestador_id,
        nota=nota,
        comentario=comentario,
    )
    saved = repository.save(db, avaliacao)
    db.commit()
    db.refresh(saved)
    publisher.publish("avaliacao.criada", _payload(saved))
    return saved


def get_da_demanda(db: Session, demanda_id: int) -> Avaliacao | None:
    return repository.get_by_demanda(db, demanda_id)


def listar_do_prestador(db: Session, prestador_id: int) -> list[Avaliacao]:
    return repository.listar_por_prestador(db, prestador_id)


def media_e_total(db: Session, prestador_id: int) -> tuple[float | None, int]:
    return repository.media_e_total(db, prestador_id)
