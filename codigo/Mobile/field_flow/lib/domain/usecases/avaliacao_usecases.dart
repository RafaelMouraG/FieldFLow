import '../entities/avaliacao.dart';
import '../repositories/avaliacao_repository.dart';

/// Registra a avaliacao do prestador apos um servico concluido.
class CriarAvaliacao {
  CriarAvaliacao(this._repo);
  final AvaliacaoRepository _repo;
  Future<Avaliacao> call(int demandaId, {required int nota, String? comentario}) =>
      _repo.criar(demandaId, nota: nota, comentario: comentario);
}

/// Obtem a avaliacao de uma demanda (ou `null` se ainda nao avaliada).
class ObterAvaliacaoDaDemanda {
  ObterAvaliacaoDaDemanda(this._repo);
  final AvaliacaoRepository _repo;
  Future<Avaliacao?> call(int demandaId) => _repo.daDemanda(demandaId);
}

/// Lista as avaliacoes recebidas por um prestador.
class ListarAvaliacoesDoPrestador {
  ListarAvaliacoesDoPrestador(this._repo);
  final AvaliacaoRepository _repo;
  Future<List<Avaliacao>> call(int prestadorId) => _repo.doPrestador(prestadorId);
}
