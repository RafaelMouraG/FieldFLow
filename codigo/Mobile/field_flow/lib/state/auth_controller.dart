import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/avaliacao_remote_datasource.dart';
import '../data/datasources/candidatura_remote_datasource.dart';
import '../data/datasources/demanda_remote_datasource.dart';
import '../data/datasources/notificacao_remote_datasource.dart';
import '../data/datasources/prestador_remote_datasource.dart';
import '../data/datasources/usuario_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/avaliacao_repository_impl.dart';
import '../data/repositories/candidatura_repository_impl.dart';
import '../data/repositories/demanda_repository_impl.dart';
import '../data/repositories/notificacao_repository_impl.dart';
import '../data/repositories/prestador_repository_impl.dart';
import '../data/repositories/usuario_repository_impl.dart';
import '../domain/entities/usuario.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/avaliacao_repository.dart';
import '../domain/repositories/candidatura_repository.dart';
import '../domain/repositories/demanda_repository.dart';
import '../domain/repositories/notificacao_repository.dart';
import '../domain/repositories/prestador_repository.dart';
import '../domain/repositories/usuario_repository.dart';
import '../domain/usecases/auth_usecases.dart';
import '../domain/usecases/avaliacao_usecases.dart';
import '../domain/usecases/candidatura_usecases.dart';
import '../domain/usecases/demanda_usecases.dart';
import '../domain/usecases/notificacao_usecases.dart';
import '../domain/usecases/prestador_usecases.dart';
import '../domain/usecases/usuario_usecases.dart';

/// Sessao do app + ponto de composicao (composition root) da Clean Architecture.
///
/// Guarda o token JWT e o usuario logado, monta a cadeia
/// datasource -> repositorio (impl) -> use case com o token vigente e expoe os
/// use cases para a camada de apresentacao (ViewModels). E o unico ponto de
/// verdade sobre "estou autenticado?": a raiz do app observa este controller
/// para decidir entre a tela de login e o fluxo autenticado.
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

  // --- Composicao: ApiClient -> datasources -> repositorios (com o token atual).
  ApiClient get _client => ApiClient(token: _token);

  AuthRepository get _authRepo =>
      AuthRepositoryImpl(AuthRemoteDataSource(_client));
  DemandaRepository get _demandaRepo =>
      DemandaRepositoryImpl(DemandaRemoteDataSource(_client));
  CandidaturaRepository get _candidaturaRepo =>
      CandidaturaRepositoryImpl(CandidaturaRemoteDataSource(_client));
  AvaliacaoRepository get _avaliacaoRepo =>
      AvaliacaoRepositoryImpl(AvaliacaoRemoteDataSource(_client));
  UsuarioRepository get _usuarioRepo =>
      UsuarioRepositoryImpl(UsuarioRemoteDataSource(_client));
  PrestadorRepository get _prestadorRepo =>
      PrestadorRepositoryImpl(PrestadorRemoteDataSource(_client));
  NotificacaoRepository get _notificacaoRepo =>
      NotificacaoRepositoryImpl(NotificacaoRemoteDataSource(_client));

  // --- Use cases expostos para os ViewModels (camada de apresentacao).
  ListarMinhasDemandas get listarDemandas =>
      ListarMinhasDemandas(_demandaRepo);
  ObterDemanda get obterDemanda => ObterDemanda(_demandaRepo);
  CriarDemanda get criarDemanda => CriarDemanda(_demandaRepo);
  AtualizarStatusDemanda get atualizarStatusDemanda =>
      AtualizarStatusDemanda(_demandaRepo);
  RemoverDemanda get removerDemanda => RemoverDemanda(_demandaRepo);

  ListarCandidaturas get listarCandidaturas =>
      ListarCandidaturas(_candidaturaRepo);
  AceitarCandidatura get aceitarCandidatura =>
      AceitarCandidatura(_candidaturaRepo);

  CriarAvaliacao get criarAvaliacao => CriarAvaliacao(_avaliacaoRepo);
  ObterAvaliacaoDaDemanda get obterAvaliacaoDaDemanda =>
      ObterAvaliacaoDaDemanda(_avaliacaoRepo);
  ListarAvaliacoesDoPrestador get listarAvaliacoesDoPrestador =>
      ListarAvaliacoesDoPrestador(_avaliacaoRepo);

  ObterUsuarioPublico get obterUsuarioPublico =>
      ObterUsuarioPublico(_usuarioRepo);
  ObterPerfilPrestador get obterPerfilPrestador =>
      ObterPerfilPrestador(_prestadorRepo);
  ListarNotificacoes get listarNotificacoes =>
      ListarNotificacoes(_notificacaoRepo);

  // --- Acoes de sessao (mutam token/usuario), implementadas via use cases.

  /// Restaura o token salvo e revalida com o use case ObterUsuarioLogado.
  /// Se o token expirou, limpa a sessao silenciosamente.
  Future<void> restaurarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved != null && saved.isNotEmpty) {
      _token = saved;
      try {
        _usuario = await ObterUsuarioLogado(_authRepo)();
      } catch (_) {
        await _limpar();
      }
    }
    _carregando = false;
    notifyListeners();
  }

  Future<void> login(String email, String senha) async {
    final token = await Login(_authRepo)(email, senha);
    await _persistir(token);
    _usuario = await ObterUsuarioLogado(_authRepo)();
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
    final res = await RegistrarCliente(_authRepo)(
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
    _usuario = await AtualizarUsuario(_usuarioRepo)(
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
      TrocarSenha(_authRepo)(senhaAtual, senhaNova);

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
