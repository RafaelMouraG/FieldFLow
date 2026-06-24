import '../../domain/entities/notificacao.dart';
import '../../domain/repositories/notificacao_repository.dart';
import '../datasources/notificacao_remote_datasource.dart';

/// Implementacao de [NotificacaoRepository] sobre o datasource remoto (REST).
class NotificacaoRepositoryImpl implements NotificacaoRepository {
  NotificacaoRepositoryImpl(this._remote);
  final NotificacaoRemoteDataSource _remote;

  @override
  Future<List<Notificacao>> listar() => _remote.listar();

  @override
  Future<void> marcarLidas() => _remote.marcarLidas();
}
