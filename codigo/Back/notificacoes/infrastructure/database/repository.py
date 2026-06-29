from sqlalchemy.orm import Session

from notificacoes.infrastructure.database.models import Notificacao

# Teto de varredura do log global antes de filtrar por usuario em memoria.
_SCAN_LIMIT = 1000


def save(db: Session, notificacao: Notificacao) -> Notificacao:
    # Sem commit: o consumer (worker._process) e quem fecha a transacao
    # depois de todos os efeitos de um evento (persist + acoes derivadas).
    db.add(notificacao)
    db.flush()
    db.refresh(notificacao)
    return notificacao


def get_by_event_id(db: Session, event_id: str) -> Notificacao | None:
    return (
        db.query(Notificacao).filter(Notificacao.event_id == event_id).first()
    )


def get_all(db: Session, limit: int = 100) -> list[Notificacao]:
    return (
        db.query(Notificacao)
        .order_by(Notificacao.id.desc())
        .limit(limit)
        .all()
    )


def get_para_usuario(
    db: Session,
    usuario_id: int,
    demanda_ids: list[int],
    limit: int = 100,
) -> list[Notificacao]:
    """Filtra o log global pelos eventos que pertencem a um usuario.

    A tabela e pequena (auditoria); varremos os mais recentes e filtramos em
    memoria sobre o payload JSON — assim ficamos independentes de operadores
    JSON especificos do banco. Um evento entra se: cita o usuario como
    cliente/prestador, refere uma das demandas dele, ou e um evento de conta
    sobre ele proprio.
    """
    dset = set(demanda_ids)
    recentes = (
        db.query(Notificacao)
        .order_by(Notificacao.id.desc())
        .limit(_SCAN_LIMIT)
        .all()
    )

    resultado: list[Notificacao] = []
    for n in recentes:
        p = n.payload or {}
        pertence = (
            p.get("cliente_id") == usuario_id
            or p.get("prestador_id") == usuario_id
            or p.get("demanda_id") in dset
            # Eventos de demanda (ex.: demanda.criada) trazem o id da demanda na
            # chave `id`, nao `demanda_id`. Para o prestador isso surfacea uma
            # nova demanda PENDENTE visivel a ele no feed (notificacao vinda do
            # evento MOM), e nao apenas via polling da lista.
            or (n.event_type == "demanda" and p.get("id") in dset)
            or (n.event_type == "usuario" and p.get("id") == usuario_id)
        )
        if pertence:
            resultado.append(n)
            if len(resultado) >= limit:
                break
    return resultado
