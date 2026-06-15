import '../../domain/entities/notificacao.dart';

/// Mapper de (de)serializacao da [Notificacao] (camada de dados).
class NotificacaoModel {
  const NotificacaoModel._();

  static Notificacao fromJson(Map<String, dynamic> json) => Notificacao(
    id: json['id'] as int,
    eventType: json['event_type'] as String,
    routingKey: json['routing_key'] as String,
    payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    criadoEm: DateTime.parse(json['criado_em'] as String),
  );
}
