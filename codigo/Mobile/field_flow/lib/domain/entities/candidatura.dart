import 'enums.dart';

/// Proposta de um prestador para uma demanda.
class Candidatura {
  Candidatura({
    required this.id,
    required this.demandaId,
    required this.prestadorId,
    required this.status,
    required this.criadoEm,
    this.mensagem,
    this.valorProposto,
  });

  final int id;
  final int demandaId;
  final int prestadorId;
  final StatusCandidatura status;
  final DateTime criadoEm;
  final String? mensagem;
  final double? valorProposto;
}
