/// Avaliacao de um prestador feita pelo cliente apos um servico concluido.
class Avaliacao {
  Avaliacao({
    required this.id,
    required this.demandaId,
    required this.autorId,
    required this.prestadorId,
    required this.nota,
    required this.criadoEm,
    this.comentario,
  });

  final int id;
  final int demandaId;
  final int autorId;
  final int prestadorId;
  final int nota;
  final DateTime criadoEm;
  final String? comentario;

  factory Avaliacao.fromJson(Map<String, dynamic> json) => Avaliacao(
    id: json['id'] as int,
    demandaId: json['demanda_id'] as int,
    autorId: json['autor_id'] as int,
    prestadorId: json['prestador_id'] as int,
    nota: json['nota'] as int,
    criadoEm: DateTime.parse(json['criado_em'] as String),
    comentario: json['comentario'] as String?,
  );
}
