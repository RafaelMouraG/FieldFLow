import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../domain/entities/candidatura.dart';
import '../../domain/entities/demanda.dart';
import '../../domain/entities/enums.dart';
import '../../state/auth_controller.dart';

/// ViewModel do acompanhamento do prestador.
///
/// Junta as candidaturas do prestador com as demandas atribuidas a ele,
/// separando o que esta "em andamento" (servicos aceitos/em execucao) das
/// candidaturas ainda pendentes/rejeitadas. Atualiza por polling.
class MinhasCandidaturasViewModel extends ChangeNotifier {
  MinhasCandidaturasViewModel(this._auth) {
    carregar();
    _timer = Timer.periodic(_intervalo, (_) => carregar(silencioso: true));
  }

  final AuthController _auth;
  static const _intervalo = Duration(seconds: 8);
  Timer? _timer;

  List<Candidatura> _candidaturas = [];
  List<Demanda> _demandas = [];

  bool _carregando = true;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  /// Mapa demandaId -> titulo, para rotular as candidaturas na lista.
  Map<int, Demanda> get _porId => {for (final d in _demandas) d.id: d};
  Demanda? demandaDe(Candidatura c) => _porId[c.demandaId];

  /// Candidaturas (propostas) do prestador, mais recentes primeiro.
  List<Candidatura> get candidaturas => _candidaturas;

  /// Servicos atribuidos a mim e em andamento (ACEITO ou EM_EXECUCAO).
  List<Demanda> get emAndamento {
    final id = _auth.usuario?.id;
    return _demandas
        .where(
          (d) =>
              d.prestadorId == id &&
              (d.status == DemandaStatus.aceito ||
                  d.status == DemandaStatus.emExecucao),
        )
        .toList();
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) {
      _carregando = true;
      notifyListeners();
    }
    try {
      final candidaturas = await _auth.listarMinhasCandidaturas();
      candidaturas.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      _candidaturas = candidaturas;
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
