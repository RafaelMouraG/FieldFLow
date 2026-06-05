import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/avaliacao.dart';
import '../models/perfil_prestador.dart';
import '../state/auth_controller.dart';

/// ViewModel da tela de perfil de um prestador (visao do cliente antes de
/// aceitar uma proposta). Busca o perfil profissional + o nome publico.
class PrestadorProfileViewModel extends ChangeNotifier {
  PrestadorProfileViewModel(this._auth, this.prestadorId) {
    carregar();
  }

  final AuthController _auth;
  final int prestadorId;

  PerfilPrestador? _perfil;
  PerfilPrestador? get perfil => _perfil;

  String? _nome;
  String? get nome => _nome;

  List<Avaliacao> _avaliacoes = [];
  List<Avaliacao> get avaliacoes => _avaliacoes;

  bool _carregando = true;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  Future<void> carregar() async {
    _carregando = true;
    notifyListeners();
    try {
      // Nome e secundario; se falhar, mostramos "Prestador #id".
      try {
        _nome = (await _auth.usuarios.obterPublico(prestadorId)).nome;
      } catch (_) {}
      _perfil = await _auth.prestadores.perfil(prestadorId);
      // Comentarios sao secundarios; se falhar, mantem o perfil visivel.
      try {
        _avaliacoes = await _auth.avaliacoes.doPrestador(prestadorId);
      } catch (_) {}
      _erro = null;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _auth.logout();
        return;
      }
      _erro = e.message;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
