import '../entities/demanda.dart';
import '../entities/enums.dart';
import '../repositories/demanda_repository.dart';

/// Lista as demandas do cliente logado.
class ListarMinhasDemandas {
  ListarMinhasDemandas(this._repo);
  final DemandaRepository _repo;
  Future<List<Demanda>> call() => _repo.listMinhas();
}

/// Obtem uma demanda pelo id.
class ObterDemanda {
  ObterDemanda(this._repo);
  final DemandaRepository _repo;
  Future<Demanda> call(int id) => _repo.obter(id);
}

/// Cria uma nova demanda.
class CriarDemanda {
  CriarDemanda(this._repo);
  final DemandaRepository _repo;
  Future<Demanda> call({
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
  }) => _repo.criar(
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
}

/// Transiciona o status de uma demanda (ex.: EM_EXECUCAO -> CONCLUIDO).
class AtualizarStatusDemanda {
  AtualizarStatusDemanda(this._repo);
  final DemandaRepository _repo;
  Future<Demanda> call(int id, DemandaStatus status) =>
      _repo.atualizarStatus(id, status);
}

/// Remove uma demanda.
class RemoverDemanda {
  RemoverDemanda(this._repo);
  final DemandaRepository _repo;
  Future<void> call(int id) => _repo.remover(id);
}
