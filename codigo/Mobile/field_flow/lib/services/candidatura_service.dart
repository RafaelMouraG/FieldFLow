import '../core/api_client.dart';
import '../models/candidatura.dart';

/// Acesso aos endpoints de candidaturas (/demandas/{id}/candidaturas, /candidaturas/*).
class CandidaturaService {
  CandidaturaService(this._client);
  final ApiClient _client;

  /// GET /demandas/{id}/candidaturas — so o cliente dono da demanda pode listar.
  Future<List<Candidatura>> listarDaDemanda(int demandaId) async {
    final res =
        await _client.get('/demandas/$demandaId/candidaturas') as List<dynamic>;
    return res
        .map((e) => Candidatura.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /candidaturas/{id}/aceitar — o cliente aceita uma proposta.
  Future<Candidatura> aceitar(int candidaturaId) async {
    final res = await _client.post('/candidaturas/$candidaturaId/aceitar');
    return Candidatura.fromJson(res as Map<String, dynamic>);
  }
}
