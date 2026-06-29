import '../../domain/entities/perfil_prestador.dart';
import '../../domain/repositories/prestador_repository.dart';
import '../datasources/prestador_remote_datasource.dart';

/// Implementacao de [PrestadorRepository] sobre o datasource remoto (REST).
class PrestadorRepositoryImpl implements PrestadorRepository {
  PrestadorRepositoryImpl(this._remote);
  final PrestadorRemoteDataSource _remote;

  @override
  Future<PerfilPrestador> perfil(int usuarioId) => _remote.perfil(usuarioId);

  @override
  Future<PerfilPrestador> meuPerfil() => _remote.meuPerfil();

  @override
  Future<PerfilPrestador> enviarPerfil({
    String? bio,
    required int anosExperiencia,
    List<String> especialidades = const [],
    List<String> certificacoes = const [],
    String? cnhCategoria,
    List<String> regioesAtuacao = const [],
    List<String> equipamentosProprios = const [],
  }) => _remote.enviarPerfil(
    bio: bio,
    anosExperiencia: anosExperiencia,
    especialidades: especialidades,
    certificacoes: certificacoes,
    cnhCategoria: cnhCategoria,
    regioesAtuacao: regioesAtuacao,
    equipamentosProprios: equipamentosProprios,
  );
}
