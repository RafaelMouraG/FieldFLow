# Sprint 3 — App Flutter (Cliente)

App mobile do **cliente** (produtor rural) do FieldFlow. Consome a API REST das
sprints anteriores, mantém o estado sincronizado por **polling** e usa **mapa**
(OpenStreetMap) para a localização das tarefas.

- Código: `codigo/Mobile/field_flow/`
- Arquitetura (diagrama de camadas + decisões): [`arquitetura.md`](arquitetura.md)

## Funcionalidades

- **Login / Cadastro** (cliente CPF ou CNPJ), sessão JWT persistida.
- **Home** com contadores por status e badge de notificações.
- **Solicitações:** listagem, detalhe, criação e acompanhamento do ciclo de vida
  (`PENDENTE → ACEITO → EM_EXECUCAO → CONCLUIDO`; o cliente marca **concluído**).
- **Mapa:** escolher o local da tarefa por pino + GPS; ver no detalhe e **abrir no
  app de mapas**. Cliente **CNPJ** define o endereço da fazenda no perfil.
- **Perfil do prestador** com reputação (nota média + comentários) antes de aceitar.
- **Notificações** (feed por usuário) e **avaliação** do prestador após o serviço.
- **Meu perfil:** editar dados e trocar senha.

## Entregas da sprint (requisitos)

| Requisito | Onde |
|---|---|
| ≥3 telas | 10 telas em `lib/screens/` (login, cadastro, home, listagem, detalhe, criação, perfil, perfil do prestador, notificações, seletor de mapa) |
| Integração REST | `lib/services/` + `lib/core/api_client.dart` |
| Atualização assíncrona | polling via `Timer.periodic` nos ViewModels (home/lista 8s, detalhe 6s, notificações 10s) |
| Arquitetura documentada | [`arquitetura.md`](arquitetura.md) — Clean Architecture + MVVM |
| App executável | roda em simulador iOS / Android; APK gerável (abaixo) |

## Pré-requisitos

1. Backend no ar: `cd infra && docker compose up -d`.
2. ⚠️ **Parar o worker de email** antes de criar/aceitar candidaturas, senão ele
   dispara emails reais via Gmail (SMTP do `.env`):
   `cd infra && docker compose stop email_worker`.
   (Os eventos `demanda.status.*` e `avaliacao.criada` não enviam email.)

## Contas de teste (seed)

| Perfil | E-mail | Senha |
|---|---|---|
| Cliente (CPF) | `cliente@fieldflow.dev` | `senha123` |
| Cliente (CNPJ — endereço da fazenda) | `fazenda@fieldflow.dev` | `senha123` |
| Prestador (aprovado) | `prestador@fieldflow.dev` | `senha123` |

> O estado de demonstração (demandas, candidaturas, avaliações) é criado via API e
> vive no volume do Postgres — **`docker compose down -v` apaga tudo**.

## Rodar

```bash
cd codigo/Mobile/field_flow
flutter pub get
flutter run            # escolha o dispositivo (simulador iOS recomendado no Mac)
```

A **base URL** da API é resolvida assim (maior prioridade primeiro):
1. Campo "Servidor" na tela de login (salvo em runtime);
2. `--dart-define=API_BASE_URL=...` no build;
3. Padrão por plataforma: Android emulador `http://10.0.2.2:8000`, demais `http://localhost:8000`.

### Celular físico (ex.: Galaxy S23)
A API roda na sua máquina, então aponte o app para o IP dela na LAN:
- No app: tela de login → **Servidor** → `http://<IP-do-PC>:8000` → Salvar; **ou**
- No build: `flutter run --dart-define=API_BASE_URL=http://<IP-do-PC>:8000`.

O `AndroidManifest.xml` já inclui `INTERNET`, permissões de localização e
`usesCleartextTraffic` (para HTTP na LAN). No iOS, `Info.plist` declara o uso de
localização.

## Gerar APK (entregável Android)

```bash
cd codigo/Mobile/field_flow
flutter build apk --release --dart-define=API_BASE_URL=http://<IP-do-PC>:8000
# saída: build/app/outputs/flutter-apk/app-release.apk
```
(Sem `--dart-define`, o APK assume `10.0.2.2:8000` — válido só em emulador Android.)

## Roteiro de validação (demo)

1. Login com a conta **cliente** → **Home** com contadores; abrir "Minhas solicitações".
2. Abrir uma demanda → detalhe com propostas e (se houver coords) **mini-mapa** +
   "Abrir no Maps". Tocar numa proposta → **perfil do prestador** (reputação).
3. **Assíncrono:** com o detalhe aberto, faça o **prestador** se candidatar
   (`POST /demandas/{id}/candidaturas` com o token do prestador). Em ~6 s a lista
   atualiza sozinha + SnackBar "Nova proposta recebida!".
4. Aceitar a proposta → demanda vira **ACEITO**; concorrentes rejeitadas em cascata
   pelo worker, refletindo no app no próximo polling.
5. **Ciclo:** prestador marca `EM_EXECUCAO` (via API); no app o cliente vê o botão
   **"Marcar como concluído"**; após concluir, aparece **"Avaliar prestador"**.
6. **Avaliação:** dar nota (1–5) + comentário → vira "Sua avaliação" e aparece no
   perfil do prestador (nota média + comentários).
7. **Nova solicitação:** preencher, **marcar o local no mapa** e publicar.
8. **CNPJ:** logar como `fazenda@fieldflow.dev` → Meu perfil → definir endereço da
   fazenda no mapa → ao criar nova solicitação o mapa abre pré-centrado nela.

## Qualidade

```bash
flutter analyze   # sem issues
flutter test      # smoke test (abre no login sem sessão)
```
