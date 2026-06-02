import logging
import sys

from core.migrations import upgrade_head
from worker.consumer import run
from worker.email_consumer import run as run_email
from worker.reprocess import reprocess_dlq

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)


def main() -> None:
    argv = sys.argv[1:]
    if argv and argv[0] == "reprocess-dlq":
        reprocess_dlq()
        return

    if argv and argv[0] == "email":
        # Segundo consumidor (Pub-Sub): processo separado para notificacao
        # por email. NAO roda upgrade_head() de proposito: a migracao fica a
        # cargo da API e do worker de negocio (que ja migram no startup). Tres
        # processos migrando o mesmo banco simultaneamente disputam a criacao
        # da tabela alembic_version (UniqueViolation). A tabela emails_enviados
        # so e lida quando chega uma mensagem, bem depois do startup do schema.
        run_email()
        return

    upgrade_head()
    run()


if __name__ == "__main__":
    main()
