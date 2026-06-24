from sqlalchemy.orm import Session

from demandas.infrastructure.database import repository as demandas_repository
from notificacoes.infrastructure.database import repository
from notificacoes.infrastructure.database.models import Notificacao
from usuarios.domain.entities import TipoUsuario
from usuarios.infrastructure.database.models import Usuario


def listar_para_usuario(
    db: Session, usuario: Usuario, limit: int = 100
) -> list[Notificacao]:
    """Notificacoes relevantes para um usuario.

    A tabela `notificacoes` e um log global de eventos da MOM; aqui filtramos
    apenas os que dizem respeito ao usuario: eventos sobre suas demandas
    (incluindo candidaturas, que carregam `demanda_id`), eventos em que ele
    aparece como `cliente_id`/`prestador_id`, e eventos sobre a propria conta.
    """
    if usuario.tipo == TipoUsuario.CLIENTE:
        demandas = demandas_repository.get_by_cliente(db, usuario.id)
    else:
        demandas = demandas_repository.get_visiveis_para_prestador(
            db, usuario.id
        )
    demanda_ids = [d.id for d in demandas]
    notificacoes = repository.get_para_usuario(
        db, usuario.id, demanda_ids, limit=limit
    )
    marca = usuario.notificacoes_lidas_ate_id or 0
    for n in notificacoes:
        # Atributo transitorio (nao mapeado) lido pelo NotificacaoResponse.
        n.lida = n.id <= marca
    return notificacoes


def marcar_lidas(db: Session, usuario: Usuario) -> None:
    """Avanca a marca d'agua do usuario para o topo do seu feed.

    Marca como lidas todas as notificacoes que o usuario ja consegue ver
    (abrir a tela = visualizar tudo). Nunca recua a marca.
    """
    feed = listar_para_usuario(db, usuario)
    if not feed:
        return
    maior_id = max(n.id for n in feed)
    if maior_id > (usuario.notificacoes_lidas_ate_id or 0):
        usuario.notificacoes_lidas_ate_id = maior_id
        db.add(usuario)
        db.commit()
