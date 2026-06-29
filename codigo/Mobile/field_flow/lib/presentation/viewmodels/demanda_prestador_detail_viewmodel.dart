import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../domain/entities/candidatura.dart';
import '../../domain/entities/demanda.dart';
import '../../domain/entities/enums.dart';
import '../../state/auth_controller.dart';

/// ViewModel do detalhe de uma demanda na visao do prestador.
///
/// Carrega a demanda e (se houver) a candidatura do proprio prestador a ela
/// (filtrando `GET /prestadores/me/candidaturas`). Orquestra candidatar-se,
/// cancelar a candidatura e iniciar a execucao (ACEITO -> EM_EXECUCAO).
/// Atualizacao assincrona por [Timer.periodic] a cada [_intervalo].
class DemandaPrestadorDetailViewModel extends ChangeNotifier {
  DemandaPrestadorDetailViewModel(this._auth, this.demandaId) {
    carregar();
    _timer = Timer.periodic(_intervalo, (_) => carregar(silencioso: true));
  }

  final AuthController _auth;
  final int demandaId;
  static const _intervalo = Duration(seconds: 6);
  Timer? _timer;

  Demanda? _demanda;
  Demanda? get demanda => _demanda;

  Candidatura? _minhaCandidatura;
  Candidatura? get minhaCandidatura => _minhaCandidatura;

  bool _carregando = true;
  bool get carregando => _carregando;

  bool _enviando = false;
  bool get enviando => _enviando;

  String? _erro;
  String? get erro => _erro;

  int? get _meuId => _auth.usuario?.id;

  /// Pode se candidatar: demanda PENDENTE e ainda sem candidatura ativa minha.
  bool get podeCandidatar =>
      _demanda?.status == DemandaStatus.pendente &&
      (_minhaCandidatura == null ||
          _minhaCandidatura!.status == StatusCandidatura.cancelada ||
          _minhaCandidatura!.status == StatusCandidatura.rejeitada);

  /// Pode cancelar a candidatura enquanto ela estiver PENDENTE.
  bool get podeCancelar =>
      _minhaCandidatura?.status == StatusCandidatura.pendente &&
      _demanda?.status == DemandaStatus.pendente;

  /// Demanda atribuida a mim e ainda nao iniciada -> posso iniciar a execucao.
  bool get podeIniciar =>
      _demanda?.status == DemandaStatus.aceito &&
      _demanda?.prestadorId == _meuId;

  /// Servico atribuido a mim e em andamento (aguardando o cliente concluir).
  bool get emExecucaoPorMim =>
      _demanda?.status == DemandaStatus.emExecucao &&
      _demanda?.prestadorId == _meuId;

  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) {
      _carregando = true;
      notifyListeners();
    }
    try {
      _demanda = await _auth.obterDemanda(demandaId);
      final minhas = await _auth.listarMinhasCandidaturas();
      _minhaCandidatura = _maisRecenteDaDemanda(minhas);
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

  Candidatura? _maisRecenteDaDemanda(List<Candidatura> minhas) {
    final daDemanda = minhas.where((c) => c.demandaId == demandaId).toList()
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return daDemanda.isEmpty ? null : daDemanda.first;
  }

  /// Candidata-se a demanda. Retorna `null` em sucesso ou a msg de erro.
  Future<String?> candidatar({String? mensagem, double? valorProposto}) async {
    _setEnviando(true);
    try {
      await _auth.candidatar(
        demandaId,
        mensagem: mensagem,
        valorProposto: valorProposto,
      );
      await carregar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _setEnviando(false);
    }
  }

  /// Cancela a candidatura ativa. Retorna `null` em sucesso ou a msg de erro.
  Future<String?> cancelar() async {
    final c = _minhaCandidatura;
    if (c == null) return null;
    _setEnviando(true);
    try {
      await _auth.cancelarCandidatura(c.id);
      await carregar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _setEnviando(false);
    }
  }

  /// Inicia a execucao do servico (ACEITO -> EM_EXECUCAO).
  /// Retorna `null` em sucesso ou a msg de erro.
  Future<String?> iniciarExecucao() async {
    _setEnviando(true);
    try {
      await _auth.atualizarStatusDemanda(demandaId, DemandaStatus.emExecucao);
      await carregar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _setEnviando(false);
    }
  }

  void _setEnviando(bool v) {
    _enviando = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
