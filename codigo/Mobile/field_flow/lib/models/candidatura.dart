import 'enums.dart';

/// Proposta de um prestador para uma demanda (CandidaturaResponse no backend).
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

  factory Candidatura.fromJson(Map<String, dynamic> json) => Candidatura(
        id: json['id'] as int,
        demandaId: json['demanda_id'] as int,
        prestadorId: json['prestador_id'] as int,
        status: StatusCandidatura.fromWire(json['status'] as String),
        criadoEm: DateTime.parse(json['criado_em'] as String),
        mensagem: json['mensagem'] as String?,
        valorProposto: (json['valor_proposto'] as num?)?.toDouble(),
      );
}
