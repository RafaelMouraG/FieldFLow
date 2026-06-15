import 'package:flutter/material.dart';

import '../../domain/entities/enums.dart';

/// Chip colorido para o status de uma demanda.
class DemandaStatusChip extends StatelessWidget {
  const DemandaStatusChip(this.status, {super.key});
  final DemandaStatus status;

  Color get _cor => switch (status) {
    DemandaStatus.pendente => Colors.orange,
    DemandaStatus.aceito => Colors.blue,
    DemandaStatus.emExecucao => Colors.purple,
    DemandaStatus.concluido => Colors.green,
  };

  @override
  Widget build(BuildContext context) => _Pill(label: status.label, cor: _cor);
}

/// Chip colorido para o status de uma candidatura.
class CandidaturaStatusChip extends StatelessWidget {
  const CandidaturaStatusChip(this.status, {super.key});
  final StatusCandidatura status;

  Color get _cor => switch (status) {
    StatusCandidatura.pendente => Colors.orange,
    StatusCandidatura.aceita => Colors.green,
    StatusCandidatura.rejeitada => Colors.red,
    StatusCandidatura.cancelada => Colors.grey,
  };

  @override
  Widget build(BuildContext context) => _Pill(label: status.label, cor: _cor);
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.cor});
  final String label;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cor.shade800AsFallback,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

extension on Color {
  /// `MaterialColor.shade800` quando disponivel; senao a propria cor escurecida.
  Color get shade800AsFallback {
    final c = this;
    if (c is MaterialColor) return c.shade800;
    return c;
  }
}
