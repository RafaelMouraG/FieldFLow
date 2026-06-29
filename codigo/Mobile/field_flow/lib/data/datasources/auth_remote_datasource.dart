import '../../core/api_client.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart' show AuthResult;
import '../models/usuario_model.dart';

/// Acesso aos endpoints de autenticacao (/auth/*).
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);
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
  }) => _register(
    nome: nome,
    email: email,
    senha: senha,
    tipoDocumento: tipoDocumento,
    documento: documento,
    tipo: 'CLIENTE',
    telefone: telefone,
  );

  /// Cadastra um prestador e ja retorna o token. O backend cria o perfil
  /// profissional como INCOMPLETO; o prestador o completa depois para aprovacao.
  Future<AuthResult> registerPrestador({
    required String nome,
    required String email,
    required String senha,
    required String tipoDocumento,
    required String documento,
    String? telefone,
  }) => _register(
    nome: nome,
    email: email,
    senha: senha,
    tipoDocumento: tipoDocumento,
    documento: documento,
    tipo: 'PRESTADOR',
    telefone: telefone,
  );

  /// POST /auth/register — cadastra um usuario do [tipo] dado e ja autentica.
  Future<AuthResult> _register({
    required String nome,
    required String email,
    required String senha,
    required String tipoDocumento,
    required String documento,
    required String tipo,
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
                'tipo': tipo,
                if (telefone != null && telefone.isNotEmpty)
                  'telefone': telefone,
              },
            )
            as Map<String, dynamic>;

    final token =
        (res['token'] as Map<String, dynamic>)['access_token'] as String;
    final usuario = UsuarioModel.fromJson(res['usuario'] as Map<String, dynamic>);
    return AuthResult(token, usuario);
  }

  Future<Usuario> me() async {
    final res = await _client.get('/auth/me');
    return UsuarioModel.fromJson(res as Map<String, dynamic>);
  }

  /// PUT /auth/me/senha — informa apenas a nova senha; resposta 204 sem corpo.
  Future<void> trocarSenha(String senhaNova) => _client.put(
    '/auth/me/senha',
    body: {'senha_nova': senhaNova},
  );
}
