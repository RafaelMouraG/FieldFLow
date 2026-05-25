"""Testes das funcoes puras de parsing/limpeza do reprocessador da DLQ.

A logica de IO (basic_get/basic_publish) nao e coberta aqui — exige broker.
"""
import pika

from worker.reprocess import _original_routing_key, _strip_x_death


def _props(headers):
    return pika.BasicProperties(headers=headers)


class TestOriginalRoutingKey:
    def test_extrai_da_primeira_entrada_de_x_death(self):
        props = _props(
            {
                "x-death": [
                    {
                        "queue": "fieldflow.notificacoes",
                        "reason": "rejected",
                        "routing-keys": ["prestador.perfil.enviado"],
                    }
                ]
            }
        )
        assert (
            _original_routing_key(props) == "prestador.perfil.enviado"
        )

    def test_retorna_none_sem_headers(self):
        assert _original_routing_key(_props(None)) is None

    def test_retorna_none_sem_x_death(self):
        assert _original_routing_key(_props({"outro": "header"})) is None

    def test_retorna_none_se_routing_keys_vazio(self):
        props = _props({"x-death": [{"routing-keys": []}]})
        assert _original_routing_key(props) is None


class TestStripXDeath:
    def test_remove_headers_de_morte_adicionados_pelo_broker(self):
        original = pika.BasicProperties(
            content_type="application/json",
            delivery_mode=2,
            message_id="evt-1",
            headers={
                "x-death": [{"routing-keys": ["x"]}],
                "x-first-death-queue": "q",
                "x-first-death-reason": "rejected",
                "x-first-death-exchange": "ex",
                "outro": "preservar",
            },
        )
        limpa = _strip_x_death(original)
        assert limpa.headers == {"outro": "preservar"}
        assert limpa.message_id == "evt-1"
        assert limpa.delivery_mode == 2
        assert limpa.content_type == "application/json"

    def test_headers_none_quando_so_havia_x_death(self):
        original = pika.BasicProperties(
            headers={"x-death": [{"routing-keys": ["x"]}]}
        )
        limpa = _strip_x_death(original)
        assert limpa.headers is None

    def test_default_delivery_mode_persistente_quando_omisso(self):
        original = pika.BasicProperties()  # delivery_mode=None
        limpa = _strip_x_death(original)
        assert limpa.delivery_mode == 2
