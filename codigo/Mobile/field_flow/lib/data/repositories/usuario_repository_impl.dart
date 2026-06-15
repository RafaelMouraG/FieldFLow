import '../../domain/entities/usuario.dart';
import '../../domain/entities/usuario_publico.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../datasources/usuario_remote_datasource.dart';

/// Implementacao de [UsuarioRepository] sobre o datasource remoto (REST).
class UsuarioRepositoryImpl implements UsuarioRepository {
  UsuarioRepositoryImpl(this._remote);
  final UsuarioRemoteDataSource _remote;

  @override
  Future<Usuario> atualizar(
    int id, {
    String? nome,
    String? email,
    String? telefone,
    String? endereco,
    double? enderecoLat,
    double? enderecoLng,
  }) => _remote.atualizar(
    id,
    nome: nome,
    email: email,
    telefone: telefone,
    endereco: endereco,
    enderecoLat: enderecoLat,
    enderecoLng: enderecoLng,
  );

  @override
  Future<UsuarioPublico> obterPublico(int id) => _remote.obterPublico(id);
}
