#!/usr/bin/env python3
"""Seed de demonstracao da Sprint 3 do FieldFlow (via API REST).

Recria um cenario de demo cobrindo todos os estados que o app Flutter exibe:
PENDENTE (com e sem proposta), ACEITO, EM_EXECUCAO e CONCLUIDO+avaliado.

Idempotente quanto aos usuarios (registra ou faz login). As demandas sao
sempre criadas de novo a cada execucao.

Uso:
    python3 scripts/seed_demo.py            # usa http://localhost:8000
    API_BASE_URL=http://host:8000 python3 scripts/seed_demo.py

Pre-requisito: o prestador@ precisa estar com o perfil APROVADO (o worker
aprova automaticamente quando anos_experiencia>=1 e certificacoes>=1; com o
worker offline, aprovar via SQL).
"""
from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

BASE = os.environ.get("API_BASE_URL", "http://localhost:8000").rstrip("/")
SENHA = "senha123"


def http(method: str, path: str, token: str | None = None, body: dict | None = None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode()
            return resp.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw)
        except json.JSONDecodeError:
            return e.code, raw


def login(email: str) -> str:
    _, body = http("POST", "/auth/login", body={"email": email, "senha": SENHA})
    return body["access_token"]


def ensure_user(email: str, payload: dict) -> str:
    """Registra (ou faz login se ja existir) e retorna o token."""
    status, body = http("POST", "/auth/register", body=payload)
    if status == 201:
        print(f"  + registrado {email} (id {body['usuario']['id']})")
        return body["token"]["access_token"]
    if status == 409 or (isinstance(body, dict) and "ja" in str(body).lower()):
        print(f"  = {email} ja existe, fazendo login")
        return login(email)
    raise SystemExit(f"Falha ao registrar {email}: {status} {body}")


def criar_demanda(token: str, **campos) -> dict:
    _, body = http("POST", "/demandas", token=token, body=campos)
    return body


def candidatar(token: str, demanda_id: int, mensagem: str, valor: float) -> dict:
    _, body = http(
        "POST",
        f"/demandas/{demanda_id}/candidaturas",
        token=token,
        body={"mensagem": mensagem, "valor_proposto": valor},
    )
    return body


def aceitar(token: str, candidatura_id: int):
    return http("POST", f"/candidaturas/{candidatura_id}/aceitar", token=token)


def status_demanda(token: str, demanda_id: int, novo: str):
    return http(
        "PATCH", f"/demandas/{demanda_id}/status", token=token, body={"status": novo}
    )


def avaliar(token: str, demanda_id: int, nota: int, comentario: str):
    return http(
        "POST",
        f"/demandas/{demanda_id}/avaliacao",
        token=token,
        body={"nota": nota, "comentario": comentario},
    )


def main() -> None:
    print(f"API: {BASE}")
    print("Usuarios:")
    cliente = ensure_user(
        "cliente@fieldflow.dev",
        {
            "nome": "Cliente Demo", "email": "cliente@fieldflow.dev", "senha": SENHA,
            "tipo": "CLIENTE", "tipo_documento": "CPF", "documento": "12345678901",
            "telefone": "31988887777",
        },
    )
    prestador = ensure_user(
        "prestador@fieldflow.dev",
        {
            "nome": "Prestador Demo", "email": "prestador@fieldflow.dev", "senha": SENHA,
            "tipo": "PRESTADOR", "tipo_documento": "CPF", "documento": "98765432100",
            "telefone": "31977776666",
        },
    )
    ensure_user(
        "fazenda@fieldflow.dev",
        {
            "nome": "Fazenda Boa Vista", "email": "fazenda@fieldflow.dev", "senha": SENHA,
            "tipo": "CLIENTE", "tipo_documento": "CNPJ", "documento": "12345678000199",
            "telefone": "3133334444",
            "endereco": "Rodovia MG-050, Km 120 - Zona Rural",
            "endereco_lat": -20.123456, "endereco_lng": -44.987654,
        },
    )

    # Garante perfil do prestador enviado (aprovacao depende do worker/SQL).
    st, _ = http("GET", "/prestadores/me/perfil", token=prestador)
    if st == 404:
        http(
            "POST", "/prestadores/me/perfil", token=prestador,
            body={
                "bio": "Operador agricola experiente.", "anos_experiencia": 6,
                "especialidades": ["Pulverizacao", "Plantio"],
                "certificacoes": [{"nome": "NR-31", "instituicao": "SENAR"}],
                "cnh_categoria": "AD", "regioes_atuacao": ["Sul de Minas"],
                "equipamentos_proprios": ["Trator"],
            },
        )
    _, perfil = http("GET", "/prestadores/me/perfil", token=prestador)
    print(f"  perfil prestador: status={perfil.get('status')}")
    if perfil.get("status") != "APROVADO":
        print("  ! ATENCAO: perfil nao esta APROVADO — candidaturas vao falhar (403).")

    coord = {"origem_lat": -19.92, "origem_lng": -43.94}
    print("\nDemandas (dono: cliente@):")

    # A — PENDENTE com proposta (cliente pode aceitar no demo)
    a = criar_demanda(
        cliente, titulo="Pulverizacao de soja - Talhao Norte",
        descricao="Aplicacao de defensivo em 80 ha, urgente para a janela climatica.",
        origem="Talhao Norte", area_hectares=80, tipo_servico="Pulverizacao",
        unidade_pagamento="POR_HECTARE", valor_recompensa=45.0, **coord,
    )
    candidatar(prestador, a["id"], "Tenho pulverizador autopropelido, disponivel amanha.", 3600.0)
    print(f"  A id={a['id']} PENDENTE (+1 proposta)")

    # B — ACEITO
    b = criar_demanda(
        cliente, titulo="Plantio de milho - Gleba 3",
        descricao="Plantio mecanizado em 120 ha.", origem="Gleba 3",
        area_hectares=120, tipo_servico="Plantio", unidade_pagamento="FIXO",
        valor_recompensa=9500.0, **coord,
    )
    cb = candidatar(prestador, b["id"], "Faco o plantio em 3 dias.", 9000.0)
    aceitar(cliente, cb["id"])
    print(f"  B id={b['id']} ACEITO")

    # C — EM_EXECUCAO
    c = criar_demanda(
        cliente, titulo="Colheita de cafe - Sitio Boa Esperanca",
        descricao="Colheita mecanizada de cafe arabica.", origem="Sitio Boa Esperanca",
        area_hectares=35, tipo_servico="Colheita", unidade_pagamento="POR_DIA",
        valor_recompensa=800.0, **coord,
    )
    cc = candidatar(prestador, c["id"], "Equipe pronta para iniciar.", 800.0)
    aceitar(cliente, cc["id"])
    status_demanda(prestador, c["id"], "EM_EXECUCAO")
    print(f"  C id={c['id']} EM_EXECUCAO")

    # D — CONCLUIDO + avaliado
    d = criar_demanda(
        cliente, titulo="Preparo de solo - Fazenda Velha",
        descricao="Gradagem e subsolagem em 60 ha.", origem="Fazenda Velha",
        area_hectares=60, tipo_servico="Preparo de solo", unidade_pagamento="FIXO",
        valor_recompensa=5200.0, **coord,
    )
    cd = candidatar(prestador, d["id"], "Maquinario disponivel.", 5000.0)
    aceitar(cliente, cd["id"])
    status_demanda(prestador, d["id"], "EM_EXECUCAO")
    status_demanda(cliente, d["id"], "CONCLUIDO")
    sa, _ = avaliar(cliente, d["id"], 5, "Excelente servico, pontual e caprichoso!")
    print(f"  D id={d['id']} CONCLUIDO + avaliado (nota 5, http {sa})")

    # E — PENDENTE sem proposta
    e = criar_demanda(
        cliente, titulo="Transporte de graos - Safra",
        descricao="Transporte de 200 sacas ate o armazem.", origem="Armazem Central",
        destino="Cooperativa", area_hectares=1, tipo_servico="Transporte",
        unidade_pagamento="A_COMBINAR", **coord,
    )
    print(f"  E id={e['id']} PENDENTE (sem proposta)")

    print("\nResumo Home (cliente@): pendentes=2, em andamento=2, concluidas=1")
    print("Pronto. Login no app: cliente@fieldflow.dev / senha123")


if __name__ == "__main__":
    main()
