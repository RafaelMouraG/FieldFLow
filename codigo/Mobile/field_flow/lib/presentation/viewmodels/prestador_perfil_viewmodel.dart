import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../domain/entities/perfil_prestador.dart';
import '../../state/auth_controller.dart';

/// ViewModel do perfil profissional do prestador (completar/enviar).
///
/// Carrega o perfil atual (status de aprovacao + reputacao) e envia a submissao
/// (`POST /prestadores/me/perfil`). O backend auto-aprova via worker quando ha
/// pelo menos 1 ano de experiencia e 1 certificacao.
class PrestadorPerfilViewModel extends ChangeNotifier {
  PrestadorPerfilViewModel(this._auth) {
    carregar();
  }

  final AuthController _auth;

  PerfilPrestador? _perfil;
  PerfilPrestador? get perfil => _perfil;

  bool _carregando = true;
  bool get carregando => _carregando;

  bool _enviando = false;
  bool get enviando => _enviando;

  String? _erro;
  String? get erro => _erro;

  Future<void> carregar() async {
    _carregando = true;
    notifyListeners();
    try {
      _perfil = await _auth.obterMeuPerfilPrestador();
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

  /// Envia o perfil para analise. Retorna `null` em sucesso ou a msg de erro.
  Future<String?> enviar({
    String? bio,
    required int anosExperiencia,
    List<String> especialidades = const [],
    List<String> certificacoes = const [],
    String? cnhCategoria,
    List<String> regioesAtuacao = const [],
    List<String> equipamentosProprios = const [],
  }) async {
    _enviando = true;
    notifyListeners();
    try {
      _perfil = await _auth.enviarPerfilPrestador(
        bio: bio,
        anosExperiencia: anosExperiencia,
        especialidades: especialidades,
        certificacoes: certificacoes,
        cnhCategoria: cnhCategoria,
        regioesAtuacao: regioesAtuacao,
        equipamentosProprios: equipamentosProprios,
      );
      // O worker auto-aprova de forma assincrona; recarrega para refletir.
      await carregar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }
}
