import '../entities/perfil_prestador.dart';
import '../repositories/prestador_repository.dart';

/// Obtem o perfil profissional de um prestador.
class ObterPerfilPrestador {
  ObterPerfilPrestador(this._repo);
  final PrestadorRepository _repo;
  Future<PerfilPrestador> call(int usuarioId) => _repo.perfil(usuarioId);
}
