import '../entities/avaliacao.dart';

/// Contrato de acesso a avaliacoes.
abstract class AvaliacaoRepository {
  Future<Avaliacao> criar(int demandaId, {required int nota, String? comentario});

  /// A avaliacao da demanda, ou `null` quando ainda nao foi avaliada.
  Future<Avaliacao?> daDemanda(int demandaId);

  Future<List<Avaliacao>> doPrestador(int prestadorId);
}
