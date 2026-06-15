/// Erro de comunicacao com a API. Carrega o status HTTP e uma mensagem
/// amigavel (extraida do campo `detail` do FastAPI quando disponivel).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// `true` quando o token expirou ou e invalido (401).
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
