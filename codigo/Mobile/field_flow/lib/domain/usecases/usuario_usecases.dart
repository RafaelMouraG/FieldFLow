import '../entities/usuario.dart';
import '../entities/usuario_publico.dart';
import '../repositories/usuario_repository.dart';

/// Atualiza dados do proprio usuario (nome/email/telefone/endereco da fazenda).
class AtualizarUsuario {
  AtualizarUsuario(this._repo);
  final UsuarioRepository _repo;
  Future<Usuario> call(
    int id, {
    String? nome,
    String? email,
    String? telefone,
    String? endereco,
    double? enderecoLat,
    double? enderecoLng,
  }) => _repo.atualizar(
    id,
    nome: nome,
    email: email,
    telefone: telefone,
    endereco: endereco,
    enderecoLat: enderecoLat,
    enderecoLng: enderecoLng,
  );
}

/// Obtem os dados publicos (id, nome, tipo) de outro usuario.
class ObterUsuarioPublico {
  ObterUsuarioPublico(this._repo);
  final UsuarioRepository _repo;
  Future<UsuarioPublico> call(int id) => _repo.obterPublico(id);
}
