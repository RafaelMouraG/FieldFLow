import '../../domain/entities/avaliacao.dart';
import '../../domain/repositories/avaliacao_repository.dart';
import '../datasources/avaliacao_remote_datasource.dart';

/// Implementacao de [AvaliacaoRepository] sobre o datasource remoto (REST).
class AvaliacaoRepositoryImpl implements AvaliacaoRepository {
  AvaliacaoRepositoryImpl(this._remote);
  final AvaliacaoRemoteDataSource _remote;

  @override
  Future<Avaliacao> criar(
    int demandaId, {
    required int nota,
    String? comentario,
  }) => _remote.criar(demandaId, nota: nota, comentario: comentario);

  @override
  Future<Avaliacao?> daDemanda(int demandaId) => _remote.daDemanda(demandaId);

  @override
  Future<List<Avaliacao>> doPrestador(int prestadorId) =>
      _remote.doPrestador(prestadorId);
}
