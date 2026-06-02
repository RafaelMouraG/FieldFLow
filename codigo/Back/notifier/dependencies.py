import logging

from core.config import settings
from notifier.interface import EmailNotifier
from notifier.noop import NoopEmailNotifier
from notifier.smtp import SmtpEmailNotifier

logger = logging.getLogger(__name__)

_notifier: EmailNotifier | None = None


def _build_notifier() -> EmailNotifier:
    if not (settings.smtp_host and settings.smtp_user and settings.smtp_password):
        logger.warning(
            "SMTP nao configurado (SMTP_HOST/SMTP_USER/SMTP_PASSWORD) — "
            "usando NoopEmailNotifier"
        )
        return NoopEmailNotifier()
    return SmtpEmailNotifier(
        host=settings.smtp_host,
        port=settings.smtp_port,
        user=settings.smtp_user,
        password=settings.smtp_password,
        from_addr=settings.smtp_from or settings.smtp_user,
        use_tls=settings.smtp_use_tls,
        timeout=settings.smtp_timeout,
    )


def get_email_notifier() -> EmailNotifier:
    global _notifier
    if _notifier is None:
        _notifier = _build_notifier()
    return _notifier
