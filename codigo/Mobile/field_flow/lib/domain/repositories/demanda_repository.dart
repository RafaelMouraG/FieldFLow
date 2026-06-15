import '../entities/demanda.dart';
import '../entities/enums.dart';

/// Contrato de acesso a demandas.
abstract class DemandaRepository {
  Future<List<Demanda>> listMinhas();

  Future<Demanda> obter(int id);

  Future<Demanda> criar({
    required String titulo,
    required String descricao,
    required String origem,
    required double areaHectares,
    required UnidadePagamento unidadePagamento,
    required String tipoServico,
    String? destino,
    double? origemLat,
    double? origemLng,
    double? destinoLat,
    double? destinoLng,
    double? valorRecompensa,
    DateTime? dataLimite,
  });

  Future<Demanda> atualizarStatus(int id, DemandaStatus status);

  Future<void> remover(int id);
}
