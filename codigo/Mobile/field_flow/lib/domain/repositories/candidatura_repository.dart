import '../entities/candidatura.dart';

/// Contrato de acesso a candidaturas.
abstract class CandidaturaRepository {
  Future<List<Candidatura>> listarDaDemanda(int demandaId);

  Future<Candidatura> aceitar(int candidaturaId);
}
