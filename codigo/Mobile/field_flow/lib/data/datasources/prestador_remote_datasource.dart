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

  /// GET /prestadores/me/perfil — perfil do prestador logado (com reputacao).
  Future<PerfilPrestador> meuPerfil() async {
    final res = await _client.get('/prestadores/me/perfil');
    return PerfilPrestadorModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /prestadores/me/perfil — envia/atualiza o perfil para analise.
  /// O worker auto-aprova se anos_experiencia >= 1 e tiver >= 1 certificacao.
  /// `certificacoes` vai como lista de objetos {"nome": ...} (formato do backend).
  Future<PerfilPrestador> enviarPerfil({
    String? bio,
    required int anosExperiencia,
    List<String> especialidades = const [],
    List<String> certificacoes = const [],
    String? cnhCategoria,
    List<String> regioesAtuacao = const [],
    List<String> equipamentosProprios = const [],
  }) async {
    final body = <String, dynamic>{
      if (bio != null && bio.isNotEmpty) 'bio': bio,
      'anos_experiencia': anosExperiencia,
      'especialidades': especialidades,
      'certificacoes': [
        for (final c in certificacoes)
          if (c.trim().isNotEmpty) {'nome': c.trim()},
      ],
      if (cnhCategoria != null && cnhCategoria.isNotEmpty)
        'cnh_categoria': cnhCategoria,
      'regioes_atuacao': regioesAtuacao,
      'equipamentos_proprios': equipamentosProprios,
    };
    final res = await _client.post('/prestadores/me/perfil', body: body);
    return PerfilPrestadorModel.fromJson(res as Map<String, dynamic>);
  }
}
