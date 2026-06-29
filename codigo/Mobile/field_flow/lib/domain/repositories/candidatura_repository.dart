import '../entities/candidatura.dart';

/// Contrato de acesso a candidaturas.
abstract class CandidaturaRepository {
  Future<List<Candidatura>> listarDaDemanda(int demandaId);

  Future<Candidatura> aceitar(int candidaturaId);

  Future<Candidatura> candidatar(
    int demandaId, {
    String? mensagem,
    double? valorProposto,
  });

  Future<Candidatura> cancelar(int candidaturaId);

  Future<List<Candidatura>> listarMinhas();
}
