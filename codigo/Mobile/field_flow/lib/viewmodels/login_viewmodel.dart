import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../state/auth_controller.dart';

/// ViewModel da tela de login. Concentra o estado de envio e a regra de
/// autenticacao; a View apenas observa `enviando` e reage ao retorno de
/// [entrar]. Nao conhece `BuildContext` nem widgets.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._auth);
  final AuthController _auth;

  bool _enviando = false;
  bool get enviando => _enviando;

  /// Tenta autenticar. Retorna `null` em sucesso ou a mensagem de erro.
  Future<String?> entrar(String email, String senha) async {
    _setEnviando(true);
    try {
      await _auth.login(email.trim(), senha);
      return null; // AuthGate troca de tela ao observar o AuthController
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
}
