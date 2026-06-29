import '../entities/usuario.dart';

/// Resultado de um registro: token JWT + usuario autenticado.
class AuthResult {
  AuthResult(this.token, this.usuario);
  final String token;
  final Usuario usuario;
}

/// Contrato de autenticacao. A camada de dados fornece a implementacao;
/// o dominio (use cases) depende apenas desta abstracao.
abstract class AuthRepository {
  Future<String> login(String email, String senha);

  Future<AuthResult> registerCliente({
    required String nome,
    required String email,
    required String senha,
    required String tipoDocumento,
    required String documento,
    String? telefone,
  });

  Future<AuthResult> registerPrestador({
    required String nome,
    required String email,
    required String senha,
    required String tipoDocumento,
    required String documento,
    String? telefone,
  });

  Future<Usuario> me();

  Future<void> trocarSenha(String senhaNova);
}
