import '../core/api_client.dart';
import '../models/demanda.dart';
import '../models/enums.dart';

/// Acesso aos endpoints de demandas (/demandas/*).
class DemandaService {
  DemandaService(this._client);
  final ApiClient _client;

  /// GET /demandas — para um cliente, retorna apenas as suas demandas.
  Future<List<Demanda>> listMinhas() async {
    final res = await _client.get('/demandas') as List<dynamic>;
    return res.map((e) => Demanda.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Demanda> obter(int id) async {
    final res = await _client.get('/demandas/$id');
    return Demanda.fromJson(res as Map<String, dynamic>);
  }

  /// POST /demandas — cria uma demanda (o cliente_id vem do JWT no backend).
  Future<Demanda> criar({
    required String titulo,
    required String descricao,
    required String origem,
    required double areaHectares,
    required UnidadePagamento unidadePagamento,
    required String tipoServico,
    String? destino,
    double? origemLat,
    double? origemLng,
    double? destinoLat,
    double? destinoLng,
    double? valorRecompensa,
    DateTime? dataLimite,
  }) async {
    final body = <String, dynamic>{
      'titulo': titulo,
      'descricao': descricao,
      'origem': origem,
      'area_hectares': areaHectares,
      'unidade_pagamento': unidadePagamento.wire,
      'tipo_servico': tipoServico,
      if (destino != null && destino.isNotEmpty) 'destino': destino,
      'origem_lat': ?origemLat,
      'origem_lng': ?origemLng,
      'destino_lat': ?destinoLat,
      'destino_lng': ?destinoLng,
      'valor_recompensa': ?valorRecompensa,
      if (dataLimite != null)
        'data_limite': dataLimite
            .toIso8601String()
            .split('T')
            .first, // YYYY-MM-DD
    };
    final res = await _client.post('/demandas', body: body);
    return Demanda.fromJson(res as Map<String, dynamic>);
  }

  /// PATCH /demandas/{id}/status — transiciona o status (ex.: cliente marca
  /// EM_EXECUCAO -> CONCLUIDO). O backend valida quem pode fazer cada transicao.
  Future<Demanda> atualizarStatus(int id, DemandaStatus status) async {
    final res = await _client.patch(
      '/demandas/$id/status',
      body: {'status': status.wire},
    );
    return Demanda.fromJson(res as Map<String, dynamic>);
  }

  Future<void> remover(int id) => _client.delete('/demandas/$id');
}
