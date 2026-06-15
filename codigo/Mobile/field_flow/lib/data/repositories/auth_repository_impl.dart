import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementacao de [AuthRepository] sobre o datasource remoto (REST).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Future<String> login(String email, String senha) =>
      _remote.login(email, senha);

  @override
  Future<AuthResult> registerCliente({
    required String nome,
    required String email,
    required String senha,
    required String tipoDocumento,
    required String documento,
    String? telefone,
  }) => _remote.registerCliente(
    nome: nome,
    email: email,
    senha: senha,
    tipoDocumento: tipoDocumento,
    documento: documento,
    telefone: telefone,
  );

  @override
  Future<Usuario> me() => _remote.me();

  @override
  Future<void> trocarSenha(String senhaAtual, String senhaNova) =>
      _remote.trocarSenha(senhaAtual, senhaNova);
}
