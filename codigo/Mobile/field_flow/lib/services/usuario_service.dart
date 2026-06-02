import '../core/api_client.dart';
import '../models/usuario.dart';
import '../models/usuario_publico.dart';

/// Acesso aos endpoints de usuarios (/usuarios/*).
class UsuarioService {
  UsuarioService(this._client);
  final ApiClient _client;

  /// PUT /usuarios/{id} — o backend so permite editar o proprio usuario.
  /// Campos editaveis (parciais): nome, email, telefone e o endereco da
  /// fazenda (endereco + coordenadas), usado por clientes CNPJ.
  Future<Usuario> atualizar(
    int id, {
    String? nome,
    String? email,
    String? telefone,
    String? endereco,
    double? enderecoLat,
    double? enderecoLng,
  }) async {
    final body = <String, dynamic>{
      'nome': ?nome,
      'email': ?email,
      'telefone': ?telefone,
      'endereco': ?endereco,
      'endereco_lat': ?enderecoLat,
      'endereco_lng': ?enderecoLng,
    };
    final res = await _client.put('/usuarios/$id', body: body);
    return Usuario.fromJson(res as Map<String, dynamic>);
  }

  /// GET /usuarios/{id} — dados publicos (id, nome, tipo) de outro usuario.
  Future<UsuarioPublico> obterPublico(int id) async {
    final res = await _client.get('/usuarios/$id');
    return UsuarioPublico.fromJson(res as Map<String, dynamic>);
  }
}
