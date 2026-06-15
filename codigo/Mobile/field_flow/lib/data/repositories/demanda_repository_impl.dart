import '../../domain/entities/demanda.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/demanda_repository.dart';
import '../datasources/demanda_remote_datasource.dart';

/// Implementacao de [DemandaRepository] sobre o datasource remoto (REST).
class DemandaRepositoryImpl implements DemandaRepository {
  DemandaRepositoryImpl(this._remote);
  final DemandaRemoteDataSource _remote;

  @override
  Future<List<Demanda>> listMinhas() => _remote.listMinhas();

  @override
  Future<Demanda> obter(int id) => _remote.obter(id);

  @override
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
  }) => _remote.criar(
    titulo: titulo,
    descricao: descricao,
    origem: origem,
    areaHectares: areaHectares,
    unidadePagamento: unidadePagamento,
    tipoServico: tipoServico,
    destino: destino,
    origemLat: origemLat,
    origemLng: origemLng,
    destinoLat: destinoLat,
    destinoLng: destinoLng,
    valorRecompensa: valorRecompensa,
    dataLimite: dataLimite,
  );

  @override
  Future<Demanda> atualizarStatus(int id, DemandaStatus status) =>
      _remote.atualizarStatus(id, status);

  @override
  Future<void> remover(int id) => _remote.remover(id);
}
