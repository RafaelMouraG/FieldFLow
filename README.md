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
| Sprint 2 | Integração MOM (RabbitMQ/Redis) | 🔄 Em andamento | 25/05/2026 |
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

## ✨ Funcionalidades Principais

- 📋 **Gestão de Demandas (Contratos):** Produtor cria solicitações com tipo de serviço, área, localização e recompensa
- 🗺️ **Painel de Oportunidades:** Prestador visualiza demandas disponíveis na sua região
- 🔔 **Notificações em Tempo Real:** MOM notifica prestadores sobre novas demandas de forma assíncrona *(Sprint 2)*
- 🔄 **Fluxo de Status Orientado a Eventos:** Ciclo de vida `PENDENTE → ACEITO → EM_EXECUCAO → CONCLUIDO`
- 📱 **App Móvel para o Cliente:** Interface Flutter para criação e acompanhamento de demandas *(Sprint 3)*
- 📱 **App Móvel para o Prestador:** Interface Flutter para aceite e execução de ordens de serviço *(Sprint 4)*

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

### 📨 Mensageria (Sprint 2)

| Tecnologia | Uso |
|---|---|
| RabbitMQ ou Redis Pub/Sub | Middleware Orientado a Mensagens (MOM) |

---

## 🏛 Arquitetura

O sistema adota uma **Arquitetura Orientada a Eventos (EDA)** com dois aplicativos móveis (cliente e prestador), um backend REST e um MOM para comunicação assíncrona.

Os diagramas completos estão em [`Documentos/diagrama-arquitetura.md`](Documentos/diagrama-arquitetura.md).

### Visão Geral

```
App Cliente (Flutter)  ──REST/JSON──▶  FieldFlow API (FastAPI)  ──SQL──▶  PostgreSQL
App Prestador (Flutter) ──REST/JSON──▶  FieldFlow API (FastAPI)
                                               │
                                         Publish eventos
                                               ▼
                                    RabbitMQ / Redis (MOM)
                                               │
                                     Notificação assíncrona
                                               ▼
                                     App Prestador (Flutter)
```

### Camadas do Backend

| Camada | Pasta | Responsabilidade |
|---|---|---|
| Controllers | `api/` | Rotas e tratamento de requisições HTTP |
| Services | `services/` | Lógica de negócio |
| Models | `models/` | Entidades SQLAlchemy (ORM) |
| Schemas | `schemas/` | Validação e serialização Pydantic |
| Config | `core/` + `database/` | Configurações e sessão do banco |

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

> ⚠️ Nunca versione o arquivo `.env`. Ele já está no `.gitignore`.

---

### 🐳 Execução com Docker Compose

A forma recomendada para rodar o projeto completo (API + banco de dados):

```bash
# Na raiz do projeto
cd infra
docker compose up --build -d
```

Verifique se os containers estão rodando:

```bash
docker ps
```

Para encerrar:

```bash
docker compose down
```

A API estará disponível em **http://localhost:8000**.

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

### Endpoints — Sprint 1

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/health` | Health check da API |
| `POST` | `/demandas` | Criar nova demanda |
| `GET` | `/demandas` | Listar todas as demandas |
| `GET` | `/demandas/{id}` | Buscar demanda por ID |
| `PATCH` | `/demandas/{id}/status` | Atualizar status (e atribuir prestador) |
| `PUT` | `/demandas/{id}` | Atualizar dados da demanda |
| `DELETE` | `/demandas/{id}` | Remover demanda |

---

## 🧪 Testes

A coleção de testes com todos os endpoints documentados, exemplos de requisição e resposta está disponível em:

📁 [`testes/fieldflow_postman_collection.json`](testes/fieldflow_postman_collection.json)

Para importar no Postman: **Import → selecione o arquivo JSON**.

A variável `{{base_url}}` já está configurada para `http://localhost:8000`.

---

## 📄 Estrutura de Pastas

```
FieldFLow/
├── .env                          # Variáveis de ambiente (não versionado)
├── .gitignore
├── README.md
├── infra/
│   └── docker-compose.yml        # Orquestração: API + PostgreSQL
├── Documentos/
│   ├── Documento de Proposta - FieldFlow.pdf
│   └── diagrama-arquitetura.md   # Diagramas Mermaid + schema do banco
├── testes/
│   └── fieldflow_postman_collection.json
└── codigo/
    ├── Back/                     # Backend FastAPI
    │   ├── Dockerfile
    │   ├── requirements.txt
    │   ├── main.py               # Entry point da aplicação
    │   ├── api/                  # Routers e controllers
    │   ├── services/             # Lógica de negócio
    │   ├── models/               # Entidades SQLAlchemy
    │   ├── schemas/              # Schemas Pydantic
    │   ├── database/             # Sessão e engine do banco
    │   └── core/                 # Configurações (pydantic-settings)
    └── Mobile/
        └── field_flow/           # App Flutter (Sprints 3 e 4)
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