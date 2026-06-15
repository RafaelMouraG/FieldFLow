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
}
