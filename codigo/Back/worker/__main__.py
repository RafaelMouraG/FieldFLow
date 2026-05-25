import logging
import sys

from core.migrations import upgrade_head
from worker.consumer import run
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

    upgrade_head()
    run()


if __name__ == "__main__":
    main()
