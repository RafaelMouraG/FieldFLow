import logging

from notifier.interface import EmailNotifier

logger = logging.getLogger(__name__)


class NoopEmailNotifier(EmailNotifier):
    """Notifier que apenas loga o email — usado quando o SMTP nao esta
    configurado (dev/CI) ou em testes. Mantem o fluxo de mensageria observavel
    sem depender de credenciais externas."""

    def send(
        self, to: str, subject: str, body: str, html_body: str | None = None
    ) -> None:
        logger.info(
            "[EMAIL-NOOP] para=%s assunto=%r html=%s corpo=%r",
            to,
            subject,
            bool(html_body),
            body,
        )
