import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'config.dart';

/// Cliente HTTP fino sobre `package:http`.
///
/// Centraliza: base URL (de [Config]), header de autenticacao (Bearer JWT),
/// serializacao JSON e traducao de respostas de erro do FastAPI em
/// [ApiException]. As camadas `services/` usam este cliente e nunca falam
/// com `package:http` diretamente.
class ApiClient {
  ApiClient({this.token});

  /// JWT atual. `null` quando o usuario ainda nao autenticou.
  final String? token;

  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path) => Uri.parse('${Config.baseUrl}$path');

  Future<dynamic> get(String path) =>
      _send(() => http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, {Object? body}) => _send(
        () => http.post(_uri(path),
            headers: _headers, body: jsonEncode(body ?? {})),
      );

  Future<dynamic> put(String path, {Object? body}) => _send(
        () => http.put(_uri(path),
            headers: _headers, body: jsonEncode(body ?? {})),
      );

  Future<dynamic> patch(String path, {Object? body}) => _send(
        () => http.patch(_uri(path),
            headers: _headers, body: jsonEncode(body ?? {})),
      );

  Future<dynamic> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(_timeout);
    } catch (e) {
      throw ApiException(
        'Nao foi possivel conectar ao servidor (${Config.baseUrl}). '
        'Verifique se a API esta no ar e se o endereco esta correto.',
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }

    throw ApiException(_extractDetail(res), statusCode: res.statusCode);
  }

  /// Extrai uma mensagem legivel do corpo de erro do FastAPI.
  /// Erros simples vem como {"detail": "..."}; erros de validacao (422)
  /// vem como {"detail": [{"loc": [...], "msg": "..."}]}.
  String _extractDetail(http.Response res) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final detail = decoded is Map ? decoded['detail'] : null;
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
      }
    } catch (_) {
      // corpo nao-JSON: cai no fallback abaixo
    }
    return 'Erro ${res.statusCode} ao falar com o servidor.';
  }
}
