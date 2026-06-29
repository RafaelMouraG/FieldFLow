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

/// O prestador se candidata a uma demanda (com valor proposto e mensagem).
class Candidatar {
  Candidatar(this._repo);
  final CandidaturaRepository _repo;
  Future<Candidatura> call(
    int demandaId, {
    String? mensagem,
    double? valorProposto,
  }) => _repo.candidatar(
    demandaId,
    mensagem: mensagem,
    valorProposto: valorProposto,
  );
}

/// O prestador cancela a propria candidatura (enquanto PENDENTE).
class CancelarCandidatura {
  CancelarCandidatura(this._repo);
  final CandidaturaRepository _repo;
  Future<Candidatura> call(int candidaturaId) => _repo.cancelar(candidaturaId);
}

/// Lista as candidaturas do prestador logado.
class ListarMinhasCandidaturas {
  ListarMinhasCandidaturas(this._repo);
  final CandidaturaRepository _repo;
  Future<List<Candidatura>> call() => _repo.listarMinhas();
}
