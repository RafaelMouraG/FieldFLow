import '../../domain/entities/perfil_prestador.dart';
import '../../domain/repositories/prestador_repository.dart';
import '../datasources/prestador_remote_datasource.dart';

/// Implementacao de [PrestadorRepository] sobre o datasource remoto (REST).
class PrestadorRepositoryImpl implements PrestadorRepository {
  PrestadorRepositoryImpl(this._remote);
  final PrestadorRemoteDataSource _remote;

  @override
  Future<PerfilPrestador> perfil(int usuarioId) => _remote.perfil(usuarioId);
}
