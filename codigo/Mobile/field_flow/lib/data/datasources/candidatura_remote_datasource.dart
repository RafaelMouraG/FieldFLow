import '../../core/api_client.dart';
import '../../domain/entities/candidatura.dart';
import '../models/candidatura_model.dart';

/// Acesso aos endpoints de candidaturas (/demandas/{id}/candidaturas, /candidaturas/*).
class CandidaturaRemoteDataSource {
  CandidaturaRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /demandas/{id}/candidaturas — so o cliente dono da demanda pode listar.
  Future<List<Candidatura>> listarDaDemanda(int demandaId) async {
    final res =
        await _client.get('/demandas/$demandaId/candidaturas') as List<dynamic>;
    return res
        .map((e) => CandidaturaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /candidaturas/{id}/aceitar — o cliente aceita uma proposta.
  Future<Candidatura> aceitar(int candidaturaId) async {
    final res = await _client.post('/candidaturas/$candidaturaId/aceitar');
    return CandidaturaModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /demandas/{id}/candidaturas — o prestador se candidata a uma demanda
  /// (exige perfil APROVADO no backend; o prestador_id vem do JWT).
  Future<Candidatura> candidatar(
    int demandaId, {
    String? mensagem,
    double? valorProposto,
  }) async {
    final body = <String, dynamic>{
      if (mensagem != null && mensagem.isNotEmpty) 'mensagem': mensagem,
      'valor_proposto': ?valorProposto,
    };
    final res = await _client.post(
      '/demandas/$demandaId/candidaturas',
      body: body,
    );
    return CandidaturaModel.fromJson(res as Map<String, dynamic>);
  }

  /// DELETE /candidaturas/{id} — o prestador cancela a propria candidatura
  /// (so enquanto PENDENTE). O backend devolve a candidatura atualizada.
  Future<Candidatura> cancelar(int candidaturaId) async {
    final res = await _client.delete('/candidaturas/$candidaturaId');
    return CandidaturaModel.fromJson(res as Map<String, dynamic>);
  }

  /// GET /prestadores/me/candidaturas — as candidaturas do prestador logado.
  Future<List<Candidatura>> listarMinhas() async {
    final res =
        await _client.get('/prestadores/me/candidaturas') as List<dynamic>;
    return res
        .map((e) => CandidaturaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
