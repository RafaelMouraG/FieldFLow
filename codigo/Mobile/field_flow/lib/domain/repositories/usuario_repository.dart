import '../entities/usuario.dart';
import '../entities/usuario_publico.dart';

/// Contrato de acesso a usuarios.
abstract class UsuarioRepository {
  Future<Usuario> atualizar(
    int id, {
    String? nome,
    String? email,
    String? telefone,
    String? endereco,
    double? enderecoLat,
    double? enderecoLng,
  });

  Future<UsuarioPublico> obterPublico(int id);
}
