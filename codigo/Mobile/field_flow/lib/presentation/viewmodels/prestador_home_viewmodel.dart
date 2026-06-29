import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../domain/entities/candidatura.dart';
import '../../domain/entities/demanda.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/perfil_prestador.dart';
import '../../state/auth_controller.dart';

/// ViewModel da Home/dashboard do prestador.
///
/// Agrega as demandas visiveis (PENDENTES + atribuidas) e as candidaturas do
/// prestador em contadores, mantem o badge de notificacoes e o status do perfil
/// (so prestadores APROVADOS podem se candidatar). Atualiza por polling
/// ([_intervalo]) — reflete novas demandas/aceites sem acao do usuario.
class PrestadorHomeViewModel extends ChangeNotifier {
  PrestadorHomeViewModel(this._auth) {
    carregar();
    _timer = Timer.periodic(_intervalo, (_) => carregar(silencioso: true));
  }

  final AuthController _auth;
  static const _intervalo = Duration(seconds: 8);
  Timer? _timer;

  List<Demanda> _demandas = [];
  List<Candidatura> _candidaturas = [];

  bool _carregando = true;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  int _notificacoes = 0;
  int get notificacoes => _notificacoes;

  PerfilPrestador? _perfil;
  PerfilPrestador? get perfil => _perfil;
  bool get perfilAprovado => _perfil?.aprovado ?? false;

  int get disponiveis =>
      _demandas.where((d) => d.status == DemandaStatus.pendente).length;

  int get emAndamento {
    final id = _auth.usuario?.id;
    return _demandas
        .where(
          (d) =>
              d.prestadorId == id &&
              (d.status == DemandaStatus.aceito ||
                  d.status == DemandaStatus.emExecucao),
        )
        .length;
  }

  int get candidaturasPendentes => _candidaturas
      .where((c) => c.status == StatusCandidatura.pendente)
      .length;

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) {
      _carregando = true;
      notifyListeners();
    }
    try {
      _demandas = await _auth.listarDemandas();
      _candidaturas = await _auth.listarMinhasCandidaturas();
      // Itens secundarios: nunca derrubam a Home se falharem.
      try {
        final lista = await _auth.listarNotificacoes();
        _notificacoes = lista.where((n) => !n.lida).length;
      } catch (_) {}
      try {
        _perfil = await _auth.obterMeuPerfilPrestador();
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
