import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/enums.dart';
import '../state/auth_controller.dart';

/// ViewModel do cadastro de cliente. Guarda o tipo de documento selecionado e
/// o estado de envio; a regra de cadastro (POST /auth/register) fica aqui.
class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this._auth);
  final AuthController _auth;

  TipoDocumento _tipoDoc = TipoDocumento.cpf;
  TipoDocumento get tipoDoc => _tipoDoc;

  bool _enviando = false;
  bool get enviando => _enviando;

  /// Quantidade de digitos esperada para o documento conforme o tipo.
  int get digitosEsperados => _tipoDoc == TipoDocumento.cpf ? 11 : 14;

  void setTipoDoc(TipoDocumento t) {
    _tipoDoc = t;
    notifyListeners();
  }

  /// Cadastra (sempre como CLIENTE). Retorna `null` em sucesso ou a msg de erro.
  Future<String?> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String documento,
    String? telefone,
  }) async {
    _setEnviando(true);
    try {
      await _auth.registrarCliente(
        nome: nome.trim(),
        email: email.trim(),
        senha: senha,
        tipoDocumento: _tipoDoc.wire,
        documento: documento.replaceAll(RegExp(r'\D'), ''),
        telefone: telefone?.trim(),
      );
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
}
