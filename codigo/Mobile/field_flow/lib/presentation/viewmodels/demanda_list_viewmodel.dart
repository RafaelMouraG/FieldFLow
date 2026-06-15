import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../domain/entities/demanda.dart';
import '../../state/auth_controller.dart';

/// ViewModel da listagem de demandas do cliente.
///
/// Responsavel pela atualizacao assincrona: um [Timer.periodic] recarrega a
/// lista a cada [_intervalo], refletindo mudancas feitas no servidor sem acao
/// do usuario. A View apenas observa `demandas`/`carregando`/`erro`.
class DemandaListViewModel extends ChangeNotifier {
  DemandaListViewModel(this._auth) {
    carregar();
    _timer = Timer.periodic(_intervalo, (_) => carregar(silencioso: true));
  }

  final AuthController _auth;
  static const _intervalo = Duration(seconds: 8);
  Timer? _timer;

  List<Demanda> _demandas = [];
  List<Demanda> get demandas => _demandas;

  bool _carregando = true;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  /// [silencioso] = recarga do polling: nao mostra spinner nem troca a tela
  /// por um estado de erro (mantem o conteudo visivel).
  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) {
      _carregando = true;
      notifyListeners();
    }
    try {
      _demandas = await _auth.listarDemandas();
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
