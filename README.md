# 🌾 FieldFlow

> Marketplace de serviços agrícolas especializados que conecta produtores rurais a prestadores técnicos qualificados.

<table>
  <tr>
    <td width="800px">
      <div align="justify">
        O <b>FieldFlow</b> é um ecossistema digital inspirado no modelo de "contratos" do simulador <i>Farming Simulator</i>. Produtores rurais publicam demandas de campo (pulverização, colheita, análise de solo) e prestadores de serviço as visualizam, aceitam e executam — tudo intermediado por uma arquitetura orientada a eventos com comunicação assíncrona via MOM.
      </div>
    </td>
  </tr>
</table>

---

## 🚦 Status do Projeto

![Python](https://img.shields.io/badge/Python-3.11-007ec6?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-007ec6?style=for-the-badge&logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-007ec6?style=for-the-badge&logo=postgresql&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.x-007ec6?style=for-the-badge&logo=flutter&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-007ec6?style=for-the-badge&logo=docker&logoColor=white)

| Sprint | Foco | Status | Prazo |
|--------|------|--------|-------|
| Sprint 1 | Backend REST + Arquitetura | ✅ Concluída | 11/05/2026 |
| Sprint 2 | Integração MOM (RabbitMQ) | ✅ Concluída | 25/05/2026 |
| Sprint 3 | App Flutter — Cliente | ⏳ Pendente | 15/06/2026 |
| Sprint 4 | App Flutter — Prestador + Entrega Final | ⏳ Pendente | 03/07/2026 |

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Funcionalidades Principais](#-funcionalidades-principais)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Arquitetura](#-arquitetura)
- [Instalação e Execução](#-instalação-e-execução)
  - [Pré-requisitos](#pré-requisitos)
  - [Variáveis de Ambiente](#-variáveis-de-ambiente)
  - [Execução com Docker Compose](#-execução-com-docker-compose)
  - [Execução Local](#-execução-local)
- [Estrutura de Pastas](#-estrutura-de-pastas)
- [Documentação da API](#-documentação-da-api)
- [Testes](#-testes)
- [Documentações Utilizadas](#-documentações-utilizadas)
- [Autor](#-autor)
- [Licença](#-licença)

---

## 📖 Sobre o Projeto

O sucesso da produção agrícola depende do cumprimento rigoroso de janelas biológicas e climáticas. Produtores rurais frequentemente dependem de terceiros para realizar intervenções críticas (pulverização, colheita, reparos emergenciais), mas enfrentam dificuldade em localizar prestadores disponíveis em momentos de pico da safra.

O **FieldFlow** resolve esse gargalo centralizando a demanda e otimizando a logística do prestador por meio de uma plataforma orientada a eventos (EDA), com comunicação assíncrona via Middleware Orientado a Mensagens (MOM).

**Contexto:** Projeto Integrador da disciplina *Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas* — PUC Minas, Engenharia de Software, 1º Semestre 2026.

---

- 🔐 **Autenticação JWT:** Registro e login com bcrypt; todos os endpoints de negócio exigem Bearer token
- 👥 **Perfis de Usuário:** Distinção clara entre CLIENTE (produtor) e PRESTADOR (técnico) com validações dedicadas
- 📋 **Gestão de Demandas:** Cliente cria solicitações com tipo de serviço, área e remuneração
- 🗺️ **Painel de Oportunidades:** Prestador aprovado visualiza demandas PENDENTES e se candidata
- ✅ **Validação de Perfil Assíncrona:** Worker valida currículo (experiência + certificações) e aprova/reprova via eventos
- 🔁 **Aceite com Rejeição em Cascata:** Ao aceitar uma candidatura, o worker rejeita automaticamente as concorrentes
- 📨 **Comunicação 100% Assíncrona:** API publica eventos no RabbitMQ; worker em processo separado consome e reage
- 🔄 **Fluxo de Status Orientado a Eventos:** Ciclo `PENDENTE → ACEITO → EM_EXECUCAO → CONCLUIDO`
- 🛡️ **Idempotência + DLQ:** `event_id` único por mensagem; falhas vão para Dead-Letter Queue
- 📱 **App Móvel para o Cliente:** Interface Flutter *(Sprint 3 — pendente)*
- 📱 **App Móvel para o Prestador:** Interface Flutter *(Sprint 4 — pendente)*

---

## 🛠 Tecnologias Utilizadas

### 🖥️ Backend

| Tecnologia | Versão | Uso |
|---|---|---|
| Python | 3.11 | Linguagem principal |
| FastAPI | 0.115+ | Framework REST |
| SQLAlchemy | 2.x | ORM |
| Pydantic | 2.x | Validação e schemas |
| PostgreSQL | 16 | Banco de dados |
| Docker / Docker Compose | — | Containerização e orquestração |

### 📱 Mobile

| Tecnologia | Versão | Uso |
|---|---|---|
| Flutter | 3.x | Framework mobile (Sprints 3 e 4) |
| Dart | 3.x | Linguagem |

### 📨 Mensageria

| Tecnologia | Versão | Uso |
|---|---|---|
| RabbitMQ | 4.3 | Middleware Orientado a Mensagens (topic exchange) |
| pika | 1.x | Cliente AMQP (publisher na API + consumer no worker) |

### 🔐 Autenticação

| Tecnologia | Uso |
|---|---|
| PyJWT | Geração e validação de tokens Bearer |
| bcrypt (via passlib) | Hash de senhas |

### 🗄️ Migrações

| Tecnologia | Uso |
|---|---|
| Alembic | Versionamento do schema PostgreSQL |

---

## 🏛 Arquitetura

O sistema adota uma **Arquitetura Orientada a Eventos (EDA)** com dois aplicativos móveis (cliente e prestador), um backend REST, um worker consumidor de eventos e um MOM (RabbitMQ) para comunicação assíncrona.

Diagramas completos: [`Documentos/Sprint 1/diagrama-arquitetura.md`](Documentos/Sprint%201/diagrama-arquitetura.md).
Catálogo de eventos: [`Documentos/Sprint 2/eventos-mom.md`](Documentos/Sprint%202/eventos-mom.md).

### Visão Geral

```
App Cliente (Flutter)   ──REST/JSON──▶  ┌─────────────────────┐  ──SQL──▶  PostgreSQL
App Prestador (Flutter) ──REST/JSON──▶  │ FieldFlow API       │              ▲
                                        │ (FastAPI + JWT)     │              │
                                        └──────────┬──────────┘              │
                                                   │ publish                 │
                                                   ▼                         │
                                        ┌─────────────────────┐              │
                                        │ RabbitMQ            │              │
                                        │ exchange topic      │              │
                                        │ fieldflow.events    │              │
                                        └──────────┬──────────┘              │
                                                   │ consume                 │
                                                   ▼                         │
                                        ┌─────────────────────┐              │
                                        │ fieldflow_worker    │──INSERT/UPDATE
                                        │ (processo separado) │
                                        └─────────────────────┘
```

A API e o worker **não trocam HTTP entre si** — toda integração passa pelo broker. Mensagens com falha vão para `fieldflow.notificacoes.dlq` via DLX.

### Organização do Backend (Clean Architecture por Bounded Context)

Cada módulo de domínio segue o mesmo molde de 4 camadas:

```
<modulo>/
├── domain/          # Entidades e enums (puro Python, sem framework)
├── application/     # Use cases (orquestram regras de negócio)
├── infrastructure/  # Repositories SQLAlchemy + adapters
└── presentation/    # Routers FastAPI + schemas Pydantic
```

| Módulo | Responsabilidade |
|---|---|
| `auth/` | Registro, login JWT, recuperação do `current_user` |
| `usuarios/` | CRUD básico de usuários (CLIENTE / PRESTADOR) |
| `prestadores/` | Perfil profissional + status (INCOMPLETO → EM_ANALISE → APROVADO/REPROVADO) |
| `demandas/` | Solicitações do cliente e transições de status |
| `candidaturas/` | Propostas de prestadores para demandas + aceite |
| `notificacoes/` | Tabela de auditoria dos eventos consumidos (evidência da Sprint 2) |
| `mom/` | Interface `EventPublisher` (DIP) + impl. RabbitMQ + Noop |
| `worker/` | Processo separado que consome `fieldflow.notificacoes` e dispara reações |
| `core/` | Configurações (pydantic-settings) e sessão SQLAlchemy |
| `alembic/` | Versionamento do schema |

---

## 🚀 Instalação e Execução

### Pré-requisitos

- [Docker](https://docs.docker.com/) e Docker Compose instalados
- Para execução local sem Docker: Python 3.11+ e PostgreSQL 16

### 🔐 Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto com base nas variáveis abaixo:

| Variável | Descrição | Exemplo |
|---|---|---|
| `POSTGRES_USER` | Usuário do banco de dados | `fieldflow_user` |
| `POSTGRES_PASSWORD` | Senha do banco de dados | `sua_senha` |
| `POSTGRES_DB` | Nome do banco de dados | `fieldflow_db` |
| `DATABASE_URL` | URL de conexão do SQLAlchemy | `postgresql://user:senha@db:5432/fieldflow_db` |
| `RABBITMQ_DEFAULT_USER` | Usuário do RabbitMQ | `fieldflow` |
| `RABBITMQ_DEFAULT_PASS` | Senha do RabbitMQ | `fieldflow` |
| `RABBITMQ_URL` | URL AMQP completa | `amqp://fieldflow:fieldflow@rabbitmq:5672/` |
| `MOM_EXCHANGE` | Nome do exchange principal | `fieldflow.events` |
| `JWT_SECRET` | Segredo para assinatura dos tokens | `troque_em_producao` |
| `JWT_ALGORITHM` | Algoritmo do JWT | `HS256` |
| `JWT_EXPIRES_MINUTES` | TTL do token em minutos | `1440` |

> ⚠️ Nunca versione o arquivo `.env`. Ele já está no `.gitignore`.

---

### 🐳 Execução com Docker Compose

A forma recomendada para rodar o projeto completo (API + worker + PostgreSQL + RabbitMQ):

```bash
# Na raiz do projeto
docker compose -f infra/docker-compose.yml up --build -d
```

Verifique se os containers estão rodando:

```bash
docker ps
```

Para encerrar (preservando dados):

```bash
docker compose -f infra/docker-compose.yml down
```

Para resetar tudo (volumes inclusos — útil após mudanças de schema sem migration):

```bash
docker compose -f infra/docker-compose.yml down -v
```

Serviços expostos:

- **API:** http://localhost:8000
- **RabbitMQ Management:** http://localhost:15672 (login: `fieldflow` / `fieldflow`)

---

### 💻 Execução Local

Caso prefira rodar sem Docker (requer PostgreSQL rodando localmente):

```bash
cd codigo/Back

# Crie e ative o ambiente virtual
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Instale as dependências
pip install -r requirements.txt

# Inicie a API
uvicorn main:app --reload
```

---

## 📚 Documentação da API

Com a API rodando, a documentação interativa gerada automaticamente pelo FastAPI está disponível em:

- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

> 🔒 Todos os endpoints abaixo (exceto `/auth/register` e `/auth/login`) exigem **Bearer JWT** no header `Authorization`.

### Auth

| Método | Rota | Descrição |
|---|---|---|
| `POST` | `/auth/register` | Registro de novo usuário (CLIENTE ou PRESTADOR) |
| `POST` | `/auth/login` | Login → retorna `access_token` |
| `GET` | `/auth/me` | Dados do usuário autenticado |
| `PUT` | `/auth/me/senha` | Alterar a própria senha |

### Usuários

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/usuarios/{id}` | Perfil público (sem documento/telefone) |
| `PUT` | `/usuarios/{id}` | Atualiza dados (apenas o próprio usuário) |
| `DELETE` | `/usuarios/{id}` | Remove conta (apenas o próprio usuário) |

### Prestadores

| Método | Rota | Descrição |
|---|---|---|
| `POST` | `/prestadores/me/perfil` | Submete currículo para análise → publica evento |
| `GET` | `/prestadores/me/perfil` | Consulta o próprio perfil profissional |
| `GET` | `/prestadores/{usuario_id}/perfil` | Consulta perfil público de outro prestador |

### Demandas

| Método | Rota | Descrição |
|---|---|---|
| `POST` | `/demandas` | Cliente cria nova demanda (publica `demanda.criada`) |
| `GET` | `/demandas` | Lista (cliente vê as suas; prestador vê PENDENTES) |
| `GET` | `/demandas/{id}` | Detalhe da demanda |
| `PUT` | `/demandas/{id}` | Atualiza (apenas dono, apenas se PENDENTE) |
| `PATCH` | `/demandas/{id}/status` | Transições EM_EXECUCAO / CONCLUIDO (aceite vai por candidatura) |
| `DELETE` | `/demandas/{id}` | Remove (apenas dono) |

### Candidaturas

| Método | Rota | Descrição |
|---|---|---|
| `POST` | `/demandas/{id}/candidaturas` | Prestador aprovado se candidata |
| `GET` | `/demandas/{id}/candidaturas` | Cliente lista candidaturas da própria demanda |
| `POST` | `/candidaturas/{id}/aceitar` | Cliente aceita → worker rejeita concorrentes em cascata |
| `DELETE` | `/candidaturas/{id}` | Prestador cancela a própria candidatura |
| `GET` | `/prestadores/me/candidaturas` | Histórico de candidaturas do prestador autenticado |

### Notificações (evidência da Sprint 2)

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/notificacoes` | Lista cronológica dos eventos consumidos pelo worker |

---

## 🧪 Testes

### Coleção Postman

A coleção com todos os endpoints documentados, exemplos de requisição e resposta está em:

📁 [`Documentos/postman/fieldflow_postman_collection.json`](Documentos/postman/fieldflow_postman_collection.json)

Para importar no Postman: **Import → selecione o arquivo JSON**.

A variável `{{base_url}}` já está configurada para `http://localhost:8000`.

### Testes automatizados

Suíte com pytest + SQLite in-memory + `FakeEventPublisher` (sem RabbitMQ):

```bash
cd codigo/Back
pytest
```

Cobertura atual: use cases de `demandas` e `candidaturas`.

### Evidências Sprint 2

Logs do worker, dumps `GET /notificacoes`, screenshots do RabbitMQ Management e descrição do cenário executado:

📁 [`Documentos/evidencias/`](Documentos/evidencias/)

---

## 📄 Estrutura de Pastas

```
FieldFLow/
├── .env                                # Variáveis de ambiente (não versionado)
├── .gitignore
├── AGENTS.md
├── README.md
├── infra/
│   └── docker-compose.yml              # API + worker + Postgres + RabbitMQ
├── Documentos/
│   ├── README.md
│   ├── Sprint 1/
│   │   ├── Documento de Proposta - FieldFlow.pdf
│   │   └── diagrama-arquitetura.md     # Mermaid + schema do banco
│   ├── Sprint 2/
│   │   ├── Relatório de Integração.pdf
│   │   ├── relatorio-mom.md
│   │   └── eventos-mom.md              # Catálogo de eventos + payloads
│   ├── evidencias/                     # Screenshots, worker.log, notificacoes.txt
│   └── postman/
│       └── fieldflow_postman_collection.json
└── codigo/
    ├── Back/                           # Backend FastAPI + worker
    │   ├── Dockerfile
    │   ├── requirements.txt
    │   ├── main.py                     # Entry point da API
    │   ├── core/                       # config + database (SQLAlchemy)
    │   ├── auth/                       # Registro/login JWT
    │   ├── usuarios/                   # CRUD de usuários
    │   ├── prestadores/                # Perfis profissionais
    │   ├── demandas/                   # Solicitações do cliente
    │   ├── candidaturas/               # Propostas + aceite
    │   ├── notificacoes/               # Auditoria dos eventos (evidência)
    │   ├── mom/                        # Interface + impl. RabbitMQ
    │   ├── worker/                     # Consumer (python -m worker)
    │   ├── alembic/                    # Migrations
    │   └── tests/                      # pytest + FakeEventPublisher
    └── Mobile/                         # App Flutter (Sprints 3 e 4)
```

---

## 📖 Documentações Utilizadas

- [FastAPI — Documentação Oficial](https://fastapi.tiangolo.com/)
- [SQLAlchemy — ORM Docs](https://docs.sqlalchemy.org/)
- [Pydantic v2 — Docs](https://docs.pydantic.dev/)
- [Flutter — Documentação Oficial](https://docs.flutter.dev/)
- [Docker Compose — Reference](https://docs.docker.com/compose/)
- [RabbitMQ — Tutorials](https://www.rabbitmq.com/tutorials)
- MARTIN, Robert C. *Arquitetura Limpa*. Alta Books, 2019.
- HOHPE, G.; WOOLF, B. *Enterprise Integration Patterns*. Addison-Wesley, 2003.

---

## 👤 Autor

| Nome | GitHub | LinkedIn |
|---|---|---|
| Rafael Ganascini de Moura | [@RafaelMouraG](https://github.com/RafaelMouraG) | — |

**Disciplina:** Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Professores:** Cleiton Silva Tavares e Cristiano de Macedo Neto  
**PUC Minas — Engenharia de Software, 2026/1**

---

## 📜 Licença

Este projeto está distribuído sob a licença MIT.