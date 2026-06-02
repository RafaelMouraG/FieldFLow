from abc import ABC, abstractmethod


class EmailNotifier(ABC):
    """Porta de saida para notificacao por email.

    Espelha o papel de `mom.EventPublisher`, mas no sentido inverso: enquanto o
    publisher leva o evento ate o broker, o notifier leva a reacao (email) ate o
    usuario. Implementacoes concretas (SMTP, SES, etc.) ficam isoladas atras
    desta interface (DIP) — o consumer e os handlers nao conhecem o provedor.
    """

    @abstractmethod
    def send(
        self, to: str, subject: str, body: str, html_body: str | None = None
    ) -> None:
        """Envia um email.

        `body` e o corpo em texto simples (fallback). Se `html_body` for
        informado, o email vai como multipart/alternative (texto + HTML) e o
        cliente escolhe a melhor representacao.

        Deve levantar excecao em caso de falha de envio, para que o consumidor
        decida o destino da mensagem (ex.: Dead-Letter Queue).
        """
        ...
