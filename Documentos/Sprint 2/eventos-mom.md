# Catálogo de Eventos — FieldFlow (Sprint 2 / MOM)

Todos os eventos são publicados no **topic exchange** `fieldflow.events` (RabbitMQ, durável). O consumidor (`fieldflow_worker`) declara a fila durável `fieldflow.notificacoes` com bindings `demanda.#`, `usuario.#`, `prestador.#` e `candidatura.#`. Cada mensagem é persistida na tabela `notificacoes` (auditoria) e dois eventos disparam reações automáticas: `prestador.perfil.enviado` (validação do perfil) e `candidatura.aceita` (rejeição em cascata das outras candidaturas).

Convenção da *routing key*: `<recurso>.<acao>[.<detalhe>]`.

**Topologia AMQP usada:**

| Recurso | Nome | Tipo / Args |
|---|---|---|
| Exchange principal | `fieldflow.events` | topic, durable |
| Fila do consumidor | `fieldflow.notificacoes` | durable, `x-dead-letter-exchange=fieldflow.events.dlx` |
| Exchange de DLQ | `fieldflow.events.dlx` | fanout, durable |
| Fila de DLQ | `fieldflow.notificacoes.dlq` | durable |

Todas as filas listadas abaixo na coluna "produtor"/"consumidor" usam essa mesma topologia (`fieldflow.events` para publicação, `fieldflow.notificacoes` para consumo).

## Tabela de eventos

| Evento (routing key) | Quando é publicado | Produtor | Ação do consumidor |
|---|---|---|---|
| `demanda.criada` | Após `POST /demandas` | `demandas.use_cases.create_demanda` | grava notificação |
| `demanda.atualizada` | Após `PUT /demandas/{id}` | `update_demanda` | grava notificação |
| `demanda.removida` | Após `DELETE /demandas/{id}` | `delete_demanda` | grava notificação |
| `demanda.status.em_execucao` | `PATCH /demandas/{id}/status` para EM_EXECUCAO | `update_demanda_status` | grava notificação |
| `demanda.status.concluido` | `PATCH ...` para CONCLUIDO | `update_demanda_status` | grava notificação |
| `demanda.status.aceito` | Cliente aceita uma candidatura | `candidaturas.use_cases.aceitar_candidatura` | grava notificação |
| `usuario.criado` | `POST /usuarios` ou `POST /auth/register` | `usuarios.use_cases.create_usuario` | grava notificação |
| `prestador.perfil.enviado` | `POST /prestadores/me/perfil` | `prestadores.use_cases.enviar_perfil` | **avalia perfil e publica resultado** |
| `prestador.aprovado` | Worker aprova | `aprovar_perfil` (chamado pelo worker) | grava notificação |
| `prestador.reprovado` | Worker reprova | `reprovar_perfil` (chamado pelo worker) | grava notificação |
| `candidatura.criada` | Prestador se candidata | `candidaturas.use_cases.candidatar` | grava notificação |
| `candidatura.aceita` | Cliente aceita candidatura | `aceitar_candidatura` | **rejeita as concorrentes em cascata** |
| `candidatura.rejeitada` | Worker rejeita concorrentes | `rejeitar_outras_candidaturas` (chamado pelo worker) | grava notificação |
| `candidatura.cancelada` | Prestador cancela própria candidatura | `cancelar_candidatura` | grava notificação |

> Senha (em texto ou hash) **nunca** integra payload de evento.

## Dois fluxos assíncronos centrais

### A) Validação do perfil do prestador
```
PRESTADOR /auth/register ─► usuário + perfil INCOMPLETO (sync)
                            ↓ publica usuario.criado
PRESTADOR /prestadores/me/perfil ─► perfil EM_ANALISE (sync, HTTP 200 imediato)
                                    ↓ publica prestador.perfil.enviado
                                    ↓
              worker valida (anos_exp ≥ 1 AND certificacoes ≥ 1)
                                    ↓
              status APROVADO ou REPROVADO no banco
                                    ↓
              publica prestador.aprovado / prestador.reprovado
```

### B) Aceite de demanda com rejeição em cascata
```
CLIENTE /demandas ─► PENDENTE (sync)
                     ↓ publica demanda.criada

PRESTADORes APROVADOs /demandas/{id}/candidaturas
                     ↓ publica candidatura.criada  (N candidaturas concorrem)

CLIENTE /candidaturas/{id_X}/aceitar ─► (sync)
   - candidatura X = ACEITA
   - demanda = ACEITO
   - publica candidatura.aceita + demanda.status.aceito
                     ↓
        worker recebe candidatura.aceita
                     ↓
        marca demais candidaturas PENDENTES da demanda como REJEITADAS
                     ↓
        publica candidatura.rejeitada (1 por candidatura concorrente)
```

A rejeição em cascata é um caso clássico de "um evento dispara N reações" — o cliente HTTP recebe resposta imediata na hora do aceite, e o trabalho de marcar/notificar os outros prestadores roda em outro processo.

## Payloads de exemplo

### `demanda.criada`
```json
{
  "id": 42, "cliente_id": 7, "prestador_id": null,
  "titulo": "Pulverização de soja - Talhão 3",
  "tipo_servico": "PULVERIZACAO", "status": "PENDENTE"
}
```

### `demanda.status.aceito`
```json
{
  "id": 42, "cliente_id": 7, "prestador_id": 19,
  "titulo": "Pulverização de soja - Talhão 3",
  "tipo_servico": "PULVERIZACAO",
  "status": "ACEITO", "status_anterior": "PENDENTE"
}
```

### `usuario.criado`
```json
{ "id": 19, "nome": "João Operador", "email": "joao@x.com", "tipo": "PRESTADOR", "tipo_documento": "CPF" }
```

### `prestador.perfil.enviado`
```json
{
  "usuario_id": 19, "status": "EM_ANALISE",
  "anos_experiencia": 5,
  "especialidades": ["PULVERIZACAO", "PLANTIO"],
  "qtd_certificacoes": 2
}
```

### `prestador.aprovado` / `prestador.reprovado`
```json
{
  "usuario_id": 19, "status": "APROVADO",
  "anos_experiencia": 5, "especialidades": [...], "qtd_certificacoes": 2
}
```

### `candidatura.criada`
```json
{
  "id": 11, "demanda_id": 42, "prestador_id": 19,
  "valor_proposto": 1500.00, "status": "PENDENTE"
}
```

### `candidatura.aceita`
```json
{
  "id": 11, "demanda_id": 42, "prestador_id": 19,
  "valor_proposto": 1500.00, "status": "ACEITA"
}
```

### `candidatura.rejeitada`
```json
{
  "id": 12, "demanda_id": 42, "prestador_id": 20,
  "valor_proposto": 1800.00, "status": "REJEITADA",
  "motivo": "outra_candidatura_aceita"
}
```

## Propriedades das mensagens AMQP
- `content_type`: `application/json` · `delivery_mode`: 2 (persistente)
- `message_id`: UUID v4 (também replicado no payload como `event_id` — usado para idempotência)
- Exchange `topic` durável, fila durável, `prefetch_count=10`
- Acks manuais; falhas usam `basic_nack(requeue=False)` → mensagem vai pra `fieldflow.notificacoes.dlq` via DLX `fieldflow.events.dlx`

## Idempotência
Cada `publish()` gera um `event_id` (UUID) único, incluído no `message_id` da AMQP e também no corpo do payload. A tabela `notificacoes` tem `UNIQUE(event_id)` e o consumer verifica antes de processar: se já existe linha com aquele `event_id`, a mensagem é descartada (`basic_ack`) sem reprocessar. Isso protege contra redelivery (queda do worker antes do ack) e contra mensagens duplicadas.

## Dead-Letter Queue
Mensagens que estouram exceção no handler são `nack`ed sem requeue. O RabbitMQ as roteia para `fieldflow.events.dlx` (fanout) → `fieldflow.notificacoes.dlq`.

**Reprocessamento manual:** `docker compose exec worker python -m worker reprocess-dlq` drena a fila, lê a routing key original do header `x-death` adicionado pelo broker e republica cada mensagem no exchange `fieldflow.events`. A dedup por `event_id` (`UNIQUE` em `notificacoes`) garante que mensagens já processadas antes do `nack` não geram linha duplicada.

> **Nota operacional:** se você tinha a fila `fieldflow.notificacoes` declarada *sem* `x-dead-letter-exchange` (versão pré-DLQ), o worker detecta o conflito (PRECONDITION_FAILED 406), loga aviso e segue em modo legacy. Para ativar a DLQ basta `docker compose down -v` (reseta volumes) e subir de novo.

## Roteiro de evidência
1. `docker compose -f infra/docker-compose.yml up --build`
2. Cadastrar 1 cliente + 2 prestadores (`POST /auth/register`).
3. Enviar perfil dos 2 prestadores (`POST /prestadores/me/perfil`) — aguardar APROVADO no worker.
4. Cliente cria demanda (`POST /demandas`).
5. Ambos prestadores se candidatam (`POST /demandas/{id}/candidaturas`).
6. Cliente lista (`GET /demandas/{id}/candidaturas`) e aceita uma (`POST /candidaturas/{id}/aceitar`).
7. Em ~1s, logs do worker mostram a rejeição em cascata da outra candidatura.
8. `GET /notificacoes` exibe a sequência cronológica completa: `demanda.criada`, `candidatura.criada` (×2), `candidatura.aceita`, `demanda.status.aceito`, `candidatura.rejeitada`.
