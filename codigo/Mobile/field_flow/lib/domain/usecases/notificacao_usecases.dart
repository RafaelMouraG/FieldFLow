import '../entities/notificacao.dart';
import '../repositories/notificacao_repository.dart';

/// Lista o feed de notificacoes do usuario.
class ListarNotificacoes {
  ListarNotificacoes(this._repo);
  final NotificacaoRepository _repo;
  Future<List<Notificacao>> call() => _repo.listar();
}
