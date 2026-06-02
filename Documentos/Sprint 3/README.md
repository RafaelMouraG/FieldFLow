# Sprint 3 — App Flutter (Cliente)

App mobile do **cliente** (produtor rural) do FieldFlow. Consome a API REST das
sprints anteriores e mantém o estado sincronizado por **polling**.

- Código: `codigo/Mobile/field_flow/`
- Arquitetura (diagrama de camadas): [`arquitetura.md`](arquitetura.md)

## Entregas da sprint

| Requisito | Onde |
|---|---|
| ≥3 telas (listagem, detalhe, criação) | `lib/screens/demanda_list_screen.dart`, `demanda_detail_screen.dart`, `demanda_form_screen.dart` (+ login/cadastro) |
| Integração REST | `lib/services/` + `lib/core/api_client.dart` |
| Atualização assíncrona | polling via `Timer.periodic` nos ViewModels (lista 8s, detalhe 6s) |
| Arquitetura documentada | [`arquitetura.md`](arquitetura.md) — Clean Architecture + MVVM |
| App executável | roda no simulador iOS / Android; APK gerável (abaixo) |

## Pré-requisitos

1. Backend no ar: `cd infra && docker compose up -d`.
2. ⚠️ **Parar o worker de email** antes de criar/aceitar candidaturas, senão ele
   dispara emails reais via Gmail (SMTP do `.env`):
   `cd infra && docker compose stop email_worker`.

## Contas de teste (seed)

| Perfil | E-mail | Senha |
|---|---|---|
| Cliente | `cliente@fieldflow.dev` | `senha123` |
| Prestador (aprovado) | `prestador@fieldflow.dev` | `senha123` |

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

## Gerar APK (entregável Android)

```bash
cd codigo/Mobile/field_flow
flutter build apk --release --dart-define=API_BASE_URL=http://<IP-do-PC>:8000
# saída: build/app/outputs/flutter-apk/app-release.apk
```
(Sem `--dart-define`, o APK assume `10.0.2.2:8000` — válido só em emulador Android.)

## Roteiro de validação (demo)

1. Login com a conta **cliente** → tela "Minhas solicitações" lista as demandas.
2. Abrir uma demanda → detalhe com as propostas recebidas.
3. **Assíncrono:** com o detalhe aberto, faça o **prestador** se candidatar
   (via app prestador na Sprint 4, ou `POST /demandas/{id}/candidaturas` com o
   token do prestador). Em até ~6 s a lista atualiza sozinha + SnackBar
   "Nova proposta recebida!".
4. Aceitar a proposta → demanda vira **ACEITO**; as concorrentes são rejeitadas
   em cascata pelo worker e isso reflete no app no próximo polling.
5. "Nova solicitação" → preencher e publicar → aparece na listagem.

## Qualidade

```bash
flutter analyze   # sem issues
flutter test      # smoke test (abre no login sem sessão)
```
