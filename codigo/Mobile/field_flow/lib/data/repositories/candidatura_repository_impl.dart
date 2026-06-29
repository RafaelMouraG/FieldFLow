import '../../domain/entities/candidatura.dart';
import '../../domain/repositories/candidatura_repository.dart';
import '../datasources/candidatura_remote_datasource.dart';

/// Implementacao de [CandidaturaRepository] sobre o datasource remoto (REST).
class CandidaturaRepositoryImpl implements CandidaturaRepository {
  CandidaturaRepositoryImpl(this._remote);
  final CandidaturaRemoteDataSource _remote;

  @override
  Future<List<Candidatura>> listarDaDemanda(int demandaId) =>
      _remote.listarDaDemanda(demandaId);

  @override
  Future<Candidatura> aceitar(int candidaturaId) =>
      _remote.aceitar(candidaturaId);

  @override
  Future<Candidatura> candidatar(
    int demandaId, {
    String? mensagem,
    double? valorProposto,
  }) => _remote.candidatar(
    demandaId,
    mensagem: mensagem,
    valorProposto: valorProposto,
  );

  @override
  Future<Candidatura> cancelar(int candidaturaId) =>
      _remote.cancelar(candidaturaId);

  @override
  Future<List<Candidatura>> listarMinhas() => _remote.listarMinhas();
}
