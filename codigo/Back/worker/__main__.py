import logging

from candidaturas.infrastructure.database import models as _c_models  # noqa: F401
from core.database import Base, engine
from demandas.infrastructure.database import models as _d_models  # noqa: F401
from notificacoes.infrastructure.database import models as _n_models  # noqa: F401
from prestadores.infrastructure.database import models as _p_models  # noqa: F401
from usuarios.infrastructure.database import models as _u_models  # noqa: F401
from worker.consumer import run

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)


def main() -> None:
    Base.metadata.create_all(bind=engine)
    run()


if __name__ == "__main__":
    main()
