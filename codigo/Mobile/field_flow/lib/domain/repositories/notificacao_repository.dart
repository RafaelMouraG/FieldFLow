import '../entities/notificacao.dart';

/// Contrato de acesso ao feed de notificacoes.
abstract class NotificacaoRepository {
  Future<List<Notificacao>> listar();
}
