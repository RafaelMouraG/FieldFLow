"""Stress publisher para evidenciar acumulo de mensagens no RabbitMQ.

Uso:
    # No host (precisa do pika instalado):
    python scripts/stress_publish.py [total] [mode]

    # Dentro do container da API (pika ja instalado):
    docker cp scripts/stress_publish.py fieldflow_api:/tmp/
    docker exec -e RABBIT_HOST=rabbitmq fieldflow_api python /tmp/stress_publish.py

Argumentos:
    total  Numero de mensagens (default: 20000)
    mode   "burst" publica o mais rapido possivel (default).
           "stream" intercala sleep de 1ms — bom para screencast.
           "dlq"   payload invalido que vai estourar no worker (popula DLQ).
"""

import json
import os
import sys
import time
import uuid

import pika

RABBIT_HOST = os.getenv("RABBIT_HOST", "localhost")
RABBIT_USER = os.getenv("RABBIT_USER", "fieldflow")
RABBIT_PASS = os.getenv("RABBIT_PASS", "fieldflow")
URL = f"amqp://{RABBIT_USER}:{RABBIT_PASS}@{RABBIT_HOST}:5672/"
EXCHANGE = os.getenv("MOM_EXCHANGE", "fieldflow.events")

TOTAL = int(sys.argv[1]) if len(sys.argv) > 1 else 20_000
MODE = sys.argv[2] if len(sys.argv) > 2 else "burst"


def make_payload(i: int, eid: str) -> tuple[str, dict]:
    if MODE == "dlq":
        # usuario_id inexistente -> handler do worker vai falhar -> nack -> DLQ
        return "prestador.perfil.enviado", {
            "event_id": eid,
            "usuario_id": 999_999_999 + i,
            "status": "EM_ANALISE",
            "anos_experiencia": 1,
            "qtd_certificacoes": 1,
        }
    return "demanda.criada", {
        "event_id": eid,
        "id": i,
        "cliente_id": 1,
        "prestador_id": None,
        "titulo": f"Stress test {i}",
        "tipo_servico": "PULVERIZACAO",
        "status": "PENDENTE",
    }


def main() -> None:
    print(f"conectando em {URL} exchange={EXCHANGE} total={TOTAL} mode={MODE}")
    connection = pika.BlockingConnection(pika.URLParameters(URL))
    channel = connection.channel()
    channel.exchange_declare(exchange=EXCHANGE, exchange_type="topic", durable=True)

    start = time.time()
    for i in range(TOTAL):
        eid = str(uuid.uuid4())
        routing_key, payload = make_payload(i, eid)
        channel.basic_publish(
            exchange=EXCHANGE,
            routing_key=routing_key,
            body=json.dumps(payload),
            properties=pika.BasicProperties(
                content_type="application/json",
                delivery_mode=2,
                message_id=eid,
            ),
        )
        if MODE == "stream":
            time.sleep(0.001)
        if (i + 1) % 1000 == 0:
            elapsed = time.time() - start
            rate = (i + 1) / elapsed
            print(f"publicadas {i+1}/{TOTAL} em {elapsed:.1f}s ({rate:.0f} msg/s)")

    connection.close()
    elapsed = time.time() - start
    print(f"FIM: {TOTAL} mensagens em {elapsed:.1f}s ({TOTAL/elapsed:.0f} msg/s)")


if __name__ == "__main__":
    main()
