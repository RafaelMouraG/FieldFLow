import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/candidatura_service.dart';
import '../services/demanda_service.dart';
import '../services/notificacao_service.dart';
import '../services/prestador_service.dart';
import '../services/usuario_service.dart';

/// Sessao do app: guarda o token JWT e o usuario logado, expoe as services
/// ja configuradas com o token atual e notifica a UI quando o login muda.
///
/// E o unico ponto de verdade sobre "estou autenticado?". A raiz do app
/// (Provider) escuta este controller para decidir entre tela de login e o
/// fluxo autenticado.
class AuthController extends ChangeNotifier {
  static const _tokenKey = 'jwt_token';

  String? _token;
  Usuario? _usuario;
  bool _carregando = true;

  String? get token => _token;
  Usuario? get usuario => _usuario;
  bool get autenticado => _token != null;

  /// `true` durante a restauracao da sessao no boot (mostra splash).
  bool get carregando => _carregando;

  ApiClient get _client => ApiClient(token: _token);
  AuthService get _auth => AuthService(_client);

  // Services prontas para as telas, sempre com o token vigente.
  DemandaService get demandas => DemandaService(_client);
  CandidaturaService get candidaturas => CandidaturaService(_client);
  UsuarioService get usuarios => UsuarioService(_client);
  PrestadorService get prestadores => PrestadorService(_client);
  NotificacaoService get notificacoes => NotificacaoService(_client);

  /// Restaura o token salvo e revalida com GET /auth/me. Se o token expirou,
  /// limpa a sessao silenciosamente.
  Future<void> restaurarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved != null && saved.isNotEmpty) {
      _token = saved;
      try {
        _usuario = await _auth.me();
      } catch (_) {
        await _limpar();
      }
    }
    _carregando = false;
    notifyListeners();
  }

  Future<void> login(String email, String senha) async {
    final token = await _auth.login(email, senha);
    await _persistir(token);
    _usuario = await _auth.me();
    notifyListeners();
  }

  Future<void> registrarCliente({
    required String nome,
    required String email,
    required String senha,
    required String tipoDocumento,
    required String documento,
    String? telefone,
  }) async {
    final res = await _auth.registerCliente(
      nome: nome,
      email: email,
      senha: senha,
      tipoDocumento: tipoDocumento,
      documento: documento,
      telefone: telefone,
    );
    await _persistir(res.token);
    _usuario = res.usuario;
    notifyListeners();
  }

  /// Atualiza dados do usuario logado (incl. endereco da fazenda) e reflete
  /// na sessao.
  Future<void> atualizarPerfil({
    String? nome,
    String? email,
    String? telefone,
    String? endereco,
    double? enderecoLat,
    double? enderecoLng,
  }) async {
    final id = _usuario!.id;
    _usuario = await usuarios.atualizar(
      id,
      nome: nome,
      email: email,
      telefone: telefone,
      endereco: endereco,
      enderecoLat: enderecoLat,
      enderecoLng: enderecoLng,
    );
    notifyListeners();
  }

  /// Troca a senha (exige a atual). Nao mexe na sessao/token.
  Future<void> trocarSenha(String senhaAtual, String senhaNova) =>
      _auth.trocarSenha(senhaAtual, senhaNova);

  Future<void> logout() async {
    await _limpar();
    notifyListeners();
  }

  Future<void> _persistir(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _limpar() async {
    _token = null;
    _usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
