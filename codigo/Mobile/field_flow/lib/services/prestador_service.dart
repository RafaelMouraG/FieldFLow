import '../core/api_client.dart';
import '../models/perfil_prestador.dart';

/// Acesso aos endpoints de prestadores (/prestadores/*).
class PrestadorService {
  PrestadorService(this._client);
  final ApiClient _client;

  /// GET /prestadores/{id}/perfil — perfil profissional publico do prestador.
  Future<PerfilPrestador> perfil(int usuarioId) async {
    final res = await _client.get('/prestadores/$usuarioId/perfil');
    return PerfilPrestador.fromJson(res as Map<String, dynamic>);
  }
}
