import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../domain/entities/avaliacao.dart';
import '../models/avaliacao_model.dart';

/// Acesso aos endpoints de avaliacoes.
class AvaliacaoRemoteDataSource {
  AvaliacaoRemoteDataSource(this._client);
  final ApiClient _client;

  /// POST /demandas/{id}/avaliacao — o cliente avalia o prestador.
  Future<Avaliacao> criar(
    int demandaId, {
    required int nota,
    String? comentario,
  }) async {
    final res = await _client.post(
      '/demandas/$demandaId/avaliacao',
      body: {
        'nota': nota,
        if (comentario != null && comentario.isNotEmpty)
          'comentario': comentario,
      },
    );
    return AvaliacaoModel.fromJson(res as Map<String, dynamic>);
  }

  /// GET /demandas/{id}/avaliacao — a avaliacao da demanda, ou `null` (404)
  /// quando ainda nao foi avaliada.
  Future<Avaliacao?> daDemanda(int demandaId) async {
    try {
      final res = await _client.get('/demandas/$demandaId/avaliacao');
      return AvaliacaoModel.fromJson(res as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// GET /prestadores/{id}/avaliacoes — avaliacoes recebidas pelo prestador.
  Future<List<Avaliacao>> doPrestador(int prestadorId) async {
    final res =
        await _client.get('/prestadores/$prestadorId/avaliacoes')
            as List<dynamic>;
    return res
        .map((e) => AvaliacaoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
