import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../domain/entities/demanda.dart';
import '../../domain/entities/enums.dart';
import '../../state/auth_controller.dart';

/// ViewModel da lista de solicitacoes disponiveis para o prestador.
///
/// Atualizacao assincrona: um [Timer.periodic] recarrega a cada [_intervalo].
/// Ao detectar uma demanda nova durante o polling, expoe uma mensagem one-shot
/// via [takeMensagem] para a View mostrar um SnackBar ("Nova solicitacao
/// disponivel!") — o prestador e notificado sem atualizar a tela manualmente.
class DemandasDisponiveisViewModel extends ChangeNotifier {
  DemandasDisponiveisViewModel(this._auth) {
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

  int _ultimaContagem = 0;
  String? _mensagem;

  /// Retorna (e limpa) uma mensagem transitoria para a View exibir uma vez.
  String? takeMensagem() {
    final m = _mensagem;
    _mensagem = null;
    return m;
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) {
      _carregando = true;
      notifyListeners();
    }
    try {
      final todas = await _auth.listarDemandas();
      final disponiveis = todas
          .where((d) => d.status == DemandaStatus.pendente)
          .toList();

      final novas = disponiveis.length - _ultimaContagem;
      if (silencioso && _ultimaContagem > 0 && novas > 0) {
        _mensagem = novas == 1
            ? 'Nova solicitação disponível!'
            : '$novas novas solicitações disponíveis!';
      }

      _demandas = disponiveis;
      _ultimaContagem = disponiveis.length;
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
