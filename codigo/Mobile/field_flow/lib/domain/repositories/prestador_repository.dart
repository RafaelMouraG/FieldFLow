import '../entities/perfil_prestador.dart';

/// Contrato de acesso ao perfil profissional de prestadores.
abstract class PrestadorRepository {
  Future<PerfilPrestador> perfil(int usuarioId);

  Future<PerfilPrestador> meuPerfil();

  Future<PerfilPrestador> enviarPerfil({
    String? bio,
    required int anosExperiencia,
    List<String> especialidades,
    List<String> certificacoes,
    String? cnhCategoria,
    List<String> regioesAtuacao,
    List<String> equipamentosProprios,
  });
}
