import '../entities/candidatura.dart';
import '../repositories/candidatura_repository.dart';

/// Lista as propostas recebidas por uma demanda.
class ListarCandidaturas {
  ListarCandidaturas(this._repo);
  final CandidaturaRepository _repo;
  Future<List<Candidatura>> call(int demandaId) =>
      _repo.listarDaDemanda(demandaId);
}

/// Aceita uma proposta (e, no backend, encerra as concorrentes em cascata).
class AceitarCandidatura {
  AceitarCandidatura(this._repo);
  final CandidaturaRepository _repo;
  Future<Candidatura> call(int candidaturaId) => _repo.aceitar(candidaturaId);
}
