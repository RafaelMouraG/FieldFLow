import '../../domain/entities/candidatura.dart';
import '../../domain/entities/enums.dart';

/// Mapper de (de)serializacao da [Candidatura] (camada de dados).
class CandidaturaModel {
  const CandidaturaModel._();

  static Candidatura fromJson(Map<String, dynamic> json) => Candidatura(
    id: json['id'] as int,
    demandaId: json['demanda_id'] as int,
    prestadorId: json['prestador_id'] as int,
    status: StatusCandidatura.fromWire(json['status'] as String),
    criadoEm: DateTime.parse(json['criado_em'] as String),
    mensagem: json['mensagem'] as String?,
    valorProposto: (json['valor_proposto'] as num?)?.toDouble(),
  );
}
