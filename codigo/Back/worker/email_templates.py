"""Templates dos emails de notificacao.

Cada funcao retorna um `RenderedEmail` com assunto, corpo em texto (fallback) e
corpo em HTML. Manter os templates aqui isola a apresentacao dos handlers: o
handler so resolve dados e dispara o envio, sem carregar HTML inline.

Os estilos sao inline de proposito — clientes de email (Gmail, Outlook) ignoram
`<style>`/CSS externo, entao layout robusto usa tabelas + style inline.
"""
from html import escape
from typing import NamedTuple

# Paleta agro do FieldFlow
_VERDE = "#2e7d32"
_VERDE_CLARO = "#43a047"
_FUNDO = "#f4f6f4"
_TEXTO = "#2b2b2b"


class RenderedEmail(NamedTuple):
    subject: str
    text: str
    html: str


def _layout(titulo: str, paragrafos_html: str, destaque: str | None = None) -> str:
    """Envolve o conteudo num card responsivo com header e footer da marca."""
    destaque_html = ""
    if destaque:
        destaque_html = f"""
              <table role="presentation" cellpadding="0" cellspacing="0" style="margin:24px 0 8px;">
                <tr>
                  <td style="background:{_VERDE_CLARO};border-radius:8px;">
                    <span style="display:inline-block;padding:12px 28px;color:#ffffff;font-weight:600;font-size:15px;">{escape(destaque)}</span>
                  </td>
                </tr>
              </table>"""
    return f"""<!doctype html>
<html lang="pt-br">
  <body style="margin:0;padding:0;background:{_FUNDO};">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:{_FUNDO};padding:24px 0;">
      <tr>
        <td align="center">
          <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:12px;overflow:hidden;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;box-shadow:0 1px 4px rgba(0,0,0,0.08);">
            <tr>
              <td style="background:{_VERDE};padding:24px 32px;">
                <span style="font-size:22px;font-weight:700;color:#ffffff;">🌾 FieldFlow</span>
              </td>
            </tr>
            <tr>
              <td style="padding:32px;color:{_TEXTO};font-size:15px;line-height:1.6;">
                <h1 style="margin:0 0 16px;font-size:20px;color:#1b1b1b;">{escape(titulo)}</h1>
                {paragrafos_html}{destaque_html}
              </td>
            </tr>
            <tr>
              <td style="padding:20px 32px;background:#eef2ee;color:#7a7a7a;font-size:12px;line-height:1.5;">
                Você recebeu este email porque tem uma conta no FieldFlow.<br>
                Marketplace de serviços agrícolas especializados.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>"""


def _p(texto_html: str) -> str:
    return f'<p style="margin:0 0 14px;">{texto_html}</p>'


def candidatura_criada(
    cliente_nome: str, prestador_nome: str, demanda_titulo: str
) -> RenderedEmail:
    subject = f"Nova candidatura na sua demanda: {demanda_titulo}"
    text = (
        f"Ola, {cliente_nome}!\n\n"
        f"{prestador_nome} se candidatou a sua demanda "
        f'"{demanda_titulo}".\n\n'
        "Acesse o FieldFlow para revisar a candidatura e decidir.\n\n"
        "-- Equipe FieldFlow"
    )
    html = _layout(
        titulo="Você recebeu uma nova candidatura",
        paragrafos_html=(
            _p(f"Olá, <strong>{escape(cliente_nome)}</strong>!")
            + _p(
                f"<strong>{escape(prestador_nome)}</strong> se candidatou à sua "
                f"demanda <strong>“{escape(demanda_titulo)}”</strong>."
            )
            + _p("Acesse o FieldFlow para revisar a candidatura e decidir.")
        ),
        destaque="Revisar candidatura",
    )
    return RenderedEmail(subject, text, html)


def candidatura_aceita(prestador_nome: str, demanda_titulo: str) -> RenderedEmail:
    subject = "Sua candidatura foi aceita! 🎉"
    text = (
        f"Parabens, {prestador_nome}!\n\n"
        f'Sua candidatura para "{demanda_titulo}" foi aceita pelo cliente.\n\n'
        "Acesse o FieldFlow para combinar os proximos passos da execucao.\n\n"
        "-- Equipe FieldFlow"
    )
    html = _layout(
        titulo="Parabéns, sua candidatura foi aceita! 🎉",
        paragrafos_html=(
            _p(f"Parabéns, <strong>{escape(prestador_nome)}</strong>!")
            + _p(
                f"Sua candidatura para <strong>“{escape(demanda_titulo)}”</strong> "
                "foi aceita pelo cliente."
            )
            + _p(
                "Acesse o FieldFlow para combinar os próximos passos da execução."
            )
        ),
        destaque="Ver detalhes da demanda",
    )
    return RenderedEmail(subject, text, html)
