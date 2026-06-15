import '../entities/perfil_prestador.dart';

/// Contrato de acesso ao perfil profissional de prestadores.
abstract class PrestadorRepository {
  Future<PerfilPrestador> perfil(int usuarioId);
}
