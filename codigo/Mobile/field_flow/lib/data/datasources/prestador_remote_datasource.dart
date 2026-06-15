import '../../core/api_client.dart';
import '../../domain/entities/perfil_prestador.dart';
import '../models/perfil_prestador_model.dart';

/// Acesso aos endpoints de prestadores (/prestadores/*).
class PrestadorRemoteDataSource {
  PrestadorRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /prestadores/{id}/perfil — perfil profissional publico do prestador.
  Future<PerfilPrestador> perfil(int usuarioId) async {
    final res = await _client.get('/prestadores/$usuarioId/perfil');
    return PerfilPrestadorModel.fromJson(res as Map<String, dynamic>);
  }
}
