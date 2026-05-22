# Relatório de Integração — Sprint 2 (MOM)
**Projeto:** FieldFlow — Marketplace de Serviços Agrícolas
**Aluno:** Rafael Moura Ganascini · **Disciplina:** LDAMD — PUC Minas, 2026/1

## Escolha da ferramenta
Adotei o **RabbitMQ 3.13** como MOM. Kafka foi descartado por complexidade operacional desnecessária para um projeto acadêmico. Redis Pub/Sub é *fire-and-forget* sem persistência — inaceitável para eventos como "demanda criada" ou "perfil enviado para análise". RabbitMQ entrega broker AMQP maduro, filas duráveis, mensagens persistentes, *routing* declarativo por padrão e UI de gerenciamento que facilita evidenciar o funcionamento.

## Padrão arquitetural
**Publish/Subscribe com Topic Exchange.** Um único exchange `fieldflow.events` (topic, durável) concentra todos os eventos. A *routing key* segue `<recurso>.<acao>[.<detalhe>]` (ex.: `demanda.status.aceito`), permitindo que novos consumidores se inscrevam sem alterar o produtor. A API publica via interface abstrata `EventPublisher` (DIP): a implementação concreta `RabbitMQEventPublisher` usa `pika` com `delivery_mode=2`; um `NoopEventPublisher` de fallback permite rodar testes sem broker. O consumidor `fieldflow_worker` é processo separado em container próprio (`python -m worker`) que declara a fila durável `fieldflow.notificacoes` com `prefetch_count=10` e ack manual.

## Casos de negócio assíncronos
Dois fluxos exemplificam a vantagem de EDA sobre orquestração síncrona:

1. **Validação de perfil do prestador** — `POST /prestadores/me/perfil` persiste com status `EM_ANALISE`, publica `prestador.perfil.enviado` e retorna 200 imediatamente. O worker valida (≥1 ano de experiência e ≥1 certificação), atualiza para APROVADO/REPROVADO e publica novo evento. Só prestadores APROVADO podem se candidatar.

2. **Rejeição em cascata** — quando o cliente aceita uma candidatura (`POST /candidaturas/{id}/aceitar`), a API publica `candidatura.aceita` + `demanda.status.aceito` e devolve 200. O worker recebe `candidatura.aceita` e marca todas as outras candidaturas PENDENTES da mesma demanda como REJEITADA, publicando um `candidatura.rejeitada` por concorrente. Caso textbook de "um evento dispara N reações" — o cliente não precisa esperar a API processar cada rejeição.

## Comunicação 100% assíncrona
```
Cliente HTTP ──► API ──publish──► RabbitMQ ──► Worker ──INSERT──► PostgreSQL
                                                  │
                              GET /notificacoes ◄─┘  (apenas leitura — evidência)
```
Produtor e consumidor **não trocam HTTP entre si**. `GET /notificacoes` é só uma janela de leitura sobre o que o worker gravou.

## Desafios e mitigações
- **Ordem de inicialização**: `depends_on: condition: service_healthy` + retry loop no worker (`_connect_with_retry`, 30×2s).
- **Acoplamento em testes**: `NoopEventPublisher` selecionado em runtime conforme presença de `RABBITMQ_URL`.
- **Worker como produtor**: validação publica `prestador.aprovado/reprovado` reusando o mesmo `EventPublisher` singleton.
- **Idempotência**: cada `publish()` gera `event_id` (UUID) no `message_id` AMQP + payload; `notificacoes` tem `UNIQUE(event_id)` e o consumer pula duplicados — resolve redelivery.
- **Dead-letter queue**: exchange `fieldflow.events.dlx` (fanout) + fila `fieldflow.notificacoes.dlq`; falhas vão pra DLQ via `nack(requeue=False)`.
- **Dados sensíveis**: senha (texto ou hash) **nunca** integra payload de evento.

## Limites e próximos passos
Permanecem como dívida assumida: (a) **outbox pattern** — uma falha entre o commit no banco e o `basic_publish` ainda pode gerar inconsistência; (b) **reprocessamento da DLQ** — hoje só inspeção manual; (c) **Alembic** — mudanças de schema ainda exigem `docker compose down -v`. Candidatos a Sprint 3 ou discussão na apresentação.
