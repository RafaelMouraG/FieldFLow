import '../core/api_client.dart';
import '../models/usuario.dart';

/// Resultado de um login/registro: token JWT + usuario autenticado.
class AuthResult {
  AuthResult(this.token, this.usuario);
  final String token;
  final Usuario usuario;
}

/// Acesso aos endpoints de autenticacao (/auth/*).
class AuthService {
  AuthService(this._client);
  final ApiClient _client;

  Future<String> login(String email, String senha) async {
    final res = await _client.post(
      '/auth/login',
      body: {'email': email, 'senha': senha},
    );
    return (res as Map<String, dynamic>)['access_token'] as String;
  }

  /// Cadastra um cliente e ja retorna o token (o backend autentica no registro).
  Future<AuthResult> registerCliente({
    required String nome,
    required String email,
    required String senha,
    required String tipoDocumento,
    required String documento,
    String? telefone,
  }) async {
    final res =
        await _client.post(
              '/auth/register',
              body: {
                'nome': nome,
                'email': email,
                'senha': senha,
                'tipo_documento': tipoDocumento,
                'documento': documento,
                'tipo': 'CLIENTE',
                if (telefone != null && telefone.isNotEmpty)
                  'telefone': telefone,
              },
            )
            as Map<String, dynamic>;

    final token =
        (res['token'] as Map<String, dynamic>)['access_token'] as String;
    final usuario = Usuario.fromJson(res['usuario'] as Map<String, dynamic>);
    return AuthResult(token, usuario);
  }

  Future<Usuario> me() async {
    final res = await _client.get('/auth/me');
    return Usuario.fromJson(res as Map<String, dynamic>);
  }

  /// PUT /auth/me/senha — exige a senha atual; resposta 204 sem corpo.
  Future<void> trocarSenha(String senhaAtual, String senhaNova) => _client.put(
    '/auth/me/senha',
    body: {'senha_atual': senhaAtual, 'senha_nova': senhaNova},
  );
}
