import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/notificacao.dart';
import '../state/auth_controller.dart';

/// ViewModel do feed de notificacoes. Recarrega por polling ([_intervalo])
/// para refletir novos eventos sem acao do usuario.
class NotificacoesViewModel extends ChangeNotifier {
  NotificacoesViewModel(this._auth) {
    carregar();
    _timer = Timer.periodic(_intervalo, (_) => carregar(silencioso: true));
  }

  final AuthController _auth;
  static const _intervalo = Duration(seconds: 10);
  Timer? _timer;

  List<Notificacao> _itens = [];
  List<Notificacao> get itens => _itens;

  bool _carregando = true;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) {
      _carregando = true;
      notifyListeners();
    }
    try {
      _itens = await _auth.notificacoes.listar();
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
