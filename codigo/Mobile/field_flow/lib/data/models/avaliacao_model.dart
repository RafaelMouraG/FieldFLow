import '../../domain/entities/avaliacao.dart';

/// Mapper de (de)serializacao da [Avaliacao] (camada de dados).
class AvaliacaoModel {
  const AvaliacaoModel._();

  static Avaliacao fromJson(Map<String, dynamic> json) => Avaliacao(
    id: json['id'] as int,
    demandaId: json['demanda_id'] as int,
    autorId: json['autor_id'] as int,
    prestadorId: json['prestador_id'] as int,
    nota: json['nota'] as int,
    criadoEm: DateTime.parse(json['criado_em'] as String),
    comentario: json['comentario'] as String?,
  );
}
