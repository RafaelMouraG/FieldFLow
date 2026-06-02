import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/candidatura.dart';
import '../models/enums.dart';
import 'status_chip.dart';

/// Cartao de uma candidatura na tela de detalhe da demanda.
/// Mostra o botao "Aceitar" apenas quando a candidatura esta PENDENTE e a
/// demanda ainda nao tem proposta aceita. Tocar no cartao abre o perfil do
/// prestador (via [onTap]).
class CandidaturaCard extends StatelessWidget {
  const CandidaturaCard({
    super.key,
    required this.candidatura,
    required this.podeAceitar,
    required this.onAceitar,
    this.onTap,
    this.aceitando = false,
  });

  final Candidatura candidatura;
  final bool podeAceitar;
  final VoidCallback onAceitar;
  final VoidCallback? onTap;
  final bool aceitando;

  @override
  Widget build(BuildContext context) {
    final c = candidatura;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text(
                      '#${c.prestadorId}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prestador #${c.prestadorId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Enviada em ${Fmt.dataHora(c.criadoEm)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CandidaturaStatusChip(c.status),
                ],
              ),
              if (c.mensagem != null && c.mensagem!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(c.mensagem!),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text('Proposta: ${Fmt.dinheiro(c.valorProposto)}'),
                ],
              ),
              if (podeAceitar && c.status == StatusCandidatura.pendente) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: aceitando ? null : onAceitar,
                    icon: aceitando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      aceitando ? 'Aceitando...' : 'Aceitar proposta',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
