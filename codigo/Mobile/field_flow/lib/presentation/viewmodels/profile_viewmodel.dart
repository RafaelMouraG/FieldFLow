import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../domain/entities/usuario.dart';
import '../../state/auth_controller.dart';

/// ViewModel da tela "Meu perfil": edicao de dados e troca de senha.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._auth);
  final AuthController _auth;

  Usuario? get usuario => _auth.usuario;

  bool _salvando = false;
  bool get salvando => _salvando;

  bool _trocandoSenha = false;
  bool get trocandoSenha => _trocandoSenha;

  bool _salvandoEndereco = false;
  bool get salvandoEndereco => _salvandoEndereco;

  /// Salva nome/email/telefone. Retorna `null` em sucesso ou a msg de erro.
  Future<String?> salvar({
    required String nome,
    required String email,
    String? telefone,
  }) async {
    _salvando = true;
    notifyListeners();
    try {
      await _auth.atualizarPerfil(nome: nome, email: email, telefone: telefone);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }

  /// Salva o endereco da fazenda (clientes CNPJ): texto + coordenadas.
  /// Retorna `null` em sucesso ou a msg de erro.
  Future<String?> salvarEndereco({
    required String endereco,
    required double lat,
    required double lng,
  }) async {
    _salvandoEndereco = true;
    notifyListeners();
    try {
      await _auth.atualizarPerfil(
        endereco: endereco,
        enderecoLat: lat,
        enderecoLng: lng,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _salvandoEndereco = false;
      notifyListeners();
    }
  }

  /// Troca a senha. Retorna `null` em sucesso ou a msg de erro.
  Future<String?> trocarSenha(String atual, String nova) async {
    _trocandoSenha = true;
    notifyListeners();
    try {
      await _auth.trocarSenha(atual, nova);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _trocandoSenha = false;
      notifyListeners();
    }
  }
}
