import logging
import smtplib
from email.message import EmailMessage

from notifier.interface import EmailNotifier

logger = logging.getLogger(__name__)


class SmtpEmailNotifier(EmailNotifier):
    """Notifier baseado em SMTP (testado com Gmail via App Password).

    Abre uma conexao por envio — simples e suficiente para o volume do worker.
    Em falha, loga e relanca para o consumer mandar a mensagem para a DLQ.
    """

    def __init__(
        self,
        host: str,
        port: int,
        user: str,
        password: str,
        from_addr: str,
        use_tls: bool = True,
        timeout: int = 10,
    ) -> None:
        self._host = host
        self._port = port
        self._user = user
        self._password = password
        self._from_addr = from_addr
        self._use_tls = use_tls
        self._timeout = timeout

    def send(self, to: str, subject: str, body: str) -> None:
        message = EmailMessage()
        message["From"] = self._from_addr
        message["To"] = to
        message["Subject"] = subject
        message.set_content(body)

        try:
            with smtplib.SMTP(
                self._host, self._port, timeout=self._timeout
            ) as smtp:
                if self._use_tls:
                    smtp.starttls()
                smtp.login(self._user, self._password)
                smtp.send_message(message)
            logger.info("[EMAIL] enviado para=%s assunto=%r", to, subject)
        except (smtplib.SMTPException, OSError) as exc:
            logger.error(
                "[EMAIL] falha ao enviar para=%s assunto=%r: %s",
                to,
                subject,
                exc,
            )
            raise
