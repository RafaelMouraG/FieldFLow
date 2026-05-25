# Documentação de Arquitetura — FieldFlow

Este diretório contém a documentação técnica, diagramas e propostas do projeto FieldFlow.

## Arquitetura do Backend (FastAPI)

O projeto adotou a **Clean Architecture (Arquitetura Limpa) Orientada a Domínio**. Isso significa que nosso código está organizado em "Módulos de Negócio" (ex: `demandas/`, `usuarios/`) e, dentro de cada módulo, o código é rigorosamente separado por sua responsabilidade arquitetural.

### Estrutura de Pastas de um Domínio

Cada domínio (ex: `codigo/Back/demandas/`) é subdividido nas seguintes camadas:

```text
nome_do_dominio/
├── domain/               # O Núcleo do Sistema (Regras Puras)
│   ├── entities.py       # Classes, Enums e lógicas que não dependem de bibliotecas externas.
│   └── exceptions.py     # (Opcional) Erros específicos do negócio.
├── application/          # Os Casos de Uso (Use Cases)
│   ├── use_cases.py      # Orquestra o fluxo de dados (ex: cria entidade, manda o DB salvar).
│   └── interfaces.py     # (Opcional) Contratos que a infraestrutura deve implementar.
├── infrastructure/       # Integrações com o Mundo Externo
│   └── database/
│       ├── models.py     # Modelos do Banco de Dados (SQLAlchemy).
│       └── repository.py # Implementação das consultas no banco (CRUD).
└── presentation/         # A Porta de Entrada (API)
    ├── router.py         # Endpoints (Rotas HTTP do FastAPI).
    └── schemas.py        # Validação de dados de entrada/saída (Pydantic).
```

### Regra de Ouro da Clean Architecture (Regra da Dependência)

> **As dependências devem sempre apontar para dentro (em direção ao `domain`).**

1. A camada `presentation` (Rotas/API) e a camada `infrastructure` (Banco de Dados) são os **detalhes** (Ficam do lado de fora).
2. A camada `application` (Casos de Uso) só pode importar o que está em `domain` (ou delegar ações para a infraestrutura).
3. A camada `domain` (Entidades) não pode importar **nada** das outras camadas (não conhece FastAPI, não conhece SQLAlchemy).

### Benefícios Dessa Abordagem

- **Alta Testabilidade:** É muito fácil testar os casos de uso (`application`) sem precisar ligar um banco de dados de verdade, apenas injetando um repositório "falso" (Mock).
- **Independência de Framework:** Se amanhã decidirmos trocar o FastAPI pelo Flask, mudamos apenas a pasta `presentation`. As regras de negócio (`domain` e `application`) continuam intactas.
- **Independência de Banco de Dados:** Se migrarmos do PostgreSQL para o MongoDB, reescrevemos apenas os arquivos dentro de `infrastructure`.

---

## Diagramas Relacionados

- **[Diagrama de Arquitetura e C4 Model](diagrama-arquitetura.md)**: Visão geral da comunicação entre os aplicativos móveis, a API e o Message Broker.
- **[Documento de Proposta](Documento%20de%20Proposta%20-%20FieldFlow.pdf)**: Contextualização e requisitos do produto.
