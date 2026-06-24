from sqlalchemy import Boolean, Column, Enum as SqlEnum, Float, Integer, String

from core.database import Base
from usuarios.domain.entities import TipoDocumento, TipoUsuario


class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String, nullable=False)
    email = Column(String, nullable=False, unique=True, index=True)
    telefone = Column(String, nullable=True)
    documento = Column(String, nullable=False, unique=True, index=True)
    tipo_documento = Column(
        SqlEnum(TipoDocumento, name="tipo_documento"), nullable=False
    )
    tipo = Column(
        SqlEnum(TipoUsuario, name="tipo_usuario"),
        nullable=False,
    )
    senha_hash = Column(String, nullable=False)
    ativo = Column(Boolean, nullable=False, default=True)
    # Endereco da fazenda/empresa (clientes CNPJ). Texto + coordenadas para
    # pre-centrar o mapa ao criar uma demanda. Opcional e independente do
    # local por-tarefa (talhao), que e definido em cada demanda.
    endereco = Column(String, nullable=True)
    endereco_lat = Column(Float, nullable=True)
    endereco_lng = Column(Float, nullable=True)
    # Marca d'agua do feed de notificacoes: maior id ja visto pelo usuario.
    # Uma notificacao e considerada lida quando seu id <= este valor. Como a
    # tabela `notificacoes` e um log global (uma linha pode pertencer a varios
    # usuarios), o estado de leitura mora aqui, por usuario.
    notificacoes_lidas_ate_id = Column(
        Integer, nullable=False, server_default="0", default=0
    )
