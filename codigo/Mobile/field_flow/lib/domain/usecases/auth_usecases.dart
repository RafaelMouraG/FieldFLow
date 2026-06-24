import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

/// Autentica um usuario e retorna o token JWT.
class Login {
  Login(this._repo);
  final AuthRepository _repo;
  Future<String> call(String email, String senha) => _repo.login(email, senha);
}

/// Cadastra um cliente (e ja retorna token + usuario).
class RegistrarCliente {
  RegistrarCliente(this._repo);
  final AuthRepository _repo;
  Future<AuthResult> call({
    required String nome,
    required String email,
    required String senha,
    required String tipoDocumento,
    required String documento,
    String? telefone,
  }) => _repo.registerCliente(
    nome: nome,
    email: email,
    senha: senha,
    tipoDocumento: tipoDocumento,
    documento: documento,
    telefone: telefone,
  );
}

/// Carrega o usuario autenticado (GET /auth/me).
class ObterUsuarioLogado {
  ObterUsuarioLogado(this._repo);
  final AuthRepository _repo;
  Future<Usuario> call() => _repo.me();
}

/// Troca a senha do usuario logado (basta a nova senha).
class TrocarSenha {
  TrocarSenha(this._repo);
  final AuthRepository _repo;
  Future<void> call(String senhaNova) => _repo.trocarSenha(senhaNova);
}
