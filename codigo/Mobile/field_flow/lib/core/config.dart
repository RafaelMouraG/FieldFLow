import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Configuracao da base URL da API REST do backend FieldFlow.
///
/// Ordem de resolucao (maior prioridade primeiro):
///   1. Override salvo em tempo de execucao (tela de login -> "Servidor").
///      Util para apontar o app rodando no celular fisico para o IP do PC.
///   2. --dart-define=API_BASE_URL=... informado no build.
///   3. Padrao por plataforma:
///        - Android (emulador): 10.0.2.2 mapeia o localhost da maquina host.
///        - iOS / web / desktop: localhost.
class Config {
  Config._();

  static const String _prefsKey = 'api_base_url';

  /// Valor passado via `flutter run --dart-define=API_BASE_URL=...`.
  static const String _fromEnv =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String _baseUrl = _platformDefault();

  /// Base URL atualmente em uso (sem barra no final).
  static String get baseUrl => _baseUrl;

  static String _platformDefault() {
    if (_fromEnv.isNotEmpty) return _strip(_fromEnv);
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  /// Carrega o override persistido (se houver). Chamado no boot do app.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = _strip(saved);
    }
  }

  /// Salva e passa a usar uma nova base URL (digitada pelo usuario).
  static Future<void> setBaseUrl(String url) async {
    _baseUrl = _strip(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _baseUrl);
  }

  static String _strip(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
