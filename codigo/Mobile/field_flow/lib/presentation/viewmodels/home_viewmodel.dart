import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../domain/entities/demanda.dart';
import '../../domain/entities/enums.dart';
import '../../state/auth_controller.dart';

/// ViewModel da Home/dashboard do cliente.
///
/// Agrega as demandas do cliente em contadores por status e mantem o total de
/// notificacoes para o badge. Atualiza por polling ([_intervalo]) — a Home
/// tambem reflete mudancas do servidor sem acao do usuario.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._auth) {
    carregar();
    _timer = Timer.periodic(_intervalo, (_) => carregar(silencioso: true));
  }

  final AuthController _auth;
  static const _intervalo = Duration(seconds: 8);
  Timer? _timer;

  List<Demanda> _demandas = [];
  bool _carregando = true;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  int _notificacoes = 0;
  int get notificacoes => _notificacoes;

  int get total => _demandas.length;
  int get pendentes =>
      _demandas.where((d) => d.status == DemandaStatus.pendente).length;
  int get emAndamento => _demandas
      .where(
        (d) =>
            d.status == DemandaStatus.aceito ||
            d.status == DemandaStatus.emExecucao,
      )
      .length;
  int get concluidas =>
      _demandas.where((d) => d.status == DemandaStatus.concluido).length;

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) {
      _carregando = true;
      notifyListeners();
    }
    try {
      _demandas = await _auth.listarDemandas();
      // O feed de notificacoes e secundario: se falhar, nao derruba a Home.
      // O badge conta apenas as nao lidas (visualizar na tela zera a contagem).
      try {
        final lista = await _auth.listarNotificacoes();
        _notificacoes = lista.where((n) => !n.lida).length;
      } catch (_) {}
      _erro = null;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _auth.logout();
        return;
      }
      if (!silencioso) _erro = e.message;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
