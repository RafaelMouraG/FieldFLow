import 'package:flutter/material.dart';

/// TELA de confirmação exibida após o prestador enviar o perfil para análise.
///
/// O backend auto-aprova (via worker/MOM) quando há experiência e certificação
/// suficientes; por isso a mensagem varia conforme o [status] resultante.
/// O botão retorna ao menu principal (remove as telas empilhadas até a Home).
class PrestadorPerfilEnviadoScreen extends StatelessWidget {
  const PrestadorPerfilEnviadoScreen({super.key, required this.status});

  /// Status do perfil após o envio (APROVADO, EM_ANALISE, REPROVADO...).
  final String status;

  bool get _aprovado => status == 'APROVADO';

  @override
  Widget build(BuildContext context) {
    final cor = _aprovado ? Colors.green : Colors.blue;
    final icone = _aprovado ? Icons.verified : Icons.hourglass_top;
    final titulo = _aprovado
        ? 'Perfil aprovado!'
        : 'Perfil enviado para análise';
    final mensagem = _aprovado
        ? 'Seu perfil profissional foi aprovado. Você já pode se candidatar '
              'às solicitações disponíveis.'
        : 'Recebemos seu perfil profissional. Assim que for aprovado, você '
              'poderá se candidatar às solicitações disponíveis.';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil profissional')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: cor.withValues(alpha: 0.12),
                  child: Icon(icone, size: 56, color: cor),
                ),
                const SizedBox(height: 24),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  mensagem,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Voltar ao menu principal'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
