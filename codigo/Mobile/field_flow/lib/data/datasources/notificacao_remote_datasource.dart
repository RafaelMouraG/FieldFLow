import '../../core/api_client.dart';
import '../../domain/entities/notificacao.dart';
import '../models/notificacao_model.dart';

/// Acesso ao feed de notificacoes do usuario (/notificacoes).
class NotificacaoRemoteDataSource {
  NotificacaoRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /notificacoes — eventos do usuario, mais recentes primeiro.
  Future<List<Notificacao>> listar() async {
    final res = await _client.get('/notificacoes') as List<dynamic>;
    return res
        .map((e) => NotificacaoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
