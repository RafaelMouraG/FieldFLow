import '../entities/perfil_prestador.dart';
import '../repositories/prestador_repository.dart';

/// Obtem o perfil profissional de um prestador.
class ObterPerfilPrestador {
  ObterPerfilPrestador(this._repo);
  final PrestadorRepository _repo;
  Future<PerfilPrestador> call(int usuarioId) => _repo.perfil(usuarioId);
}

/// Obtem o perfil do prestador logado (com status de aprovacao + reputacao).
class ObterMeuPerfilPrestador {
  ObterMeuPerfilPrestador(this._repo);
  final PrestadorRepository _repo;
  Future<PerfilPrestador> call() => _repo.meuPerfil();
}

/// Envia/atualiza o perfil profissional do prestador para analise.
class EnviarPerfilPrestador {
  EnviarPerfilPrestador(this._repo);
  final PrestadorRepository _repo;
  Future<PerfilPrestador> call({
    String? bio,
    required int anosExperiencia,
    List<String> especialidades = const [],
    List<String> certificacoes = const [],
    String? cnhCategoria,
    List<String> regioesAtuacao = const [],
    List<String> equipamentosProprios = const [],
  }) => _repo.enviarPerfil(
    bio: bio,
    anosExperiencia: anosExperiencia,
    especialidades: especialidades,
    certificacoes: certificacoes,
    cnhCategoria: cnhCategoria,
    regioesAtuacao: regioesAtuacao,
    equipamentosProprios: equipamentosProprios,
  );
}
