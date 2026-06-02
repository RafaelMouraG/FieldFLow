import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/candidatura.dart';
import '../models/demanda.dart';
import '../models/enums.dart';
import '../state/auth_controller.dart';

/// ViewModel do detalhe da demanda + candidaturas.
///
/// Atualizacao assincrona: [Timer.periodic] recarrega demanda e candidaturas a
/// cada [_intervalo]. Quando chega proposta nova durante o polling, expoe uma
/// mensagem one-shot via [takeMensagem] para a View mostrar um SnackBar.
class DemandaDetailViewModel extends ChangeNotifier {
  DemandaDetailViewModel(this._auth, this.demandaId) {
    carregar();
    _timer = Timer.periodic(_intervalo, (_) => carregar(silencioso: true));
  }

  final AuthController _auth;
  final int demandaId;
  static const _intervalo = Duration(seconds: 6);
  Timer? _timer;

  Demanda? _demanda;
  Demanda? get demanda => _demanda;

  List<Candidatura> _candidaturas = [];
  List<Candidatura> get candidaturas => _candidaturas;

  bool _carregando = true;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  int? _aceitandoId;
  int? get aceitandoId => _aceitandoId;

  int _ultimaContagem = 0;
  String? _mensagem;

  /// So pode aceitar propostas enquanto a demanda estiver PENDENTE.
  bool get podeAceitar => _demanda?.status == DemandaStatus.pendente;

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
      final demanda = await _auth.demandas.obter(demandaId);
      final candidaturas = await _auth.candidaturas.listarDaDemanda(demandaId);

      final novas = candidaturas.length - _ultimaContagem;
      if (silencioso && _ultimaContagem > 0 && novas > 0) {
        _mensagem = novas == 1
            ? 'Nova proposta recebida!'
            : '$novas novas propostas recebidas!';
      }

      _demanda = demanda;
      _candidaturas = candidaturas;
      _ultimaContagem = candidaturas.length;
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

  /// Aceita uma proposta. Retorna `null` em sucesso ou a msg de erro.
  Future<String?> aceitar(Candidatura c) async {
    _aceitandoId = c.id;
    notifyListeners();
    try {
      await _auth.candidaturas.aceitar(c.id);
      await carregar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _aceitandoId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
