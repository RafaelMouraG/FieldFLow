/// Evento registrado para o usuario (GET /notificacoes).
///
/// O backend grava o evento cru (routing_key + payload da MOM); a traducao
/// para um texto amigavel em pt-BR fica em [titulo]/[descricao].
class Notificacao {
  Notificacao({
    required this.id,
    required this.eventType,
    required this.routingKey,
    required this.payload,
    required this.criadoEm,
  });

  final int id;
  final String eventType;
  final String routingKey;
  final Map<String, dynamic> payload;
  final DateTime criadoEm;

  factory Notificacao.fromJson(Map<String, dynamic> json) => Notificacao(
    id: json['id'] as int,
    eventType: json['event_type'] as String,
    routingKey: json['routing_key'] as String,
    payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    criadoEm: DateTime.parse(json['criado_em'] as String),
  );

  /// Titulo curto conforme a routing key do evento.
  String get titulo => switch (routingKey) {
    'candidatura.criada' => 'Nova proposta recebida',
    'candidatura.aceita' => 'Proposta aceita',
    'candidatura.rejeitada' => 'Proposta recusada',
    'candidatura.cancelada' => 'Proposta cancelada',
    'demanda.criada' => 'Solicitacao criada',
    'demanda.atualizada' => 'Solicitacao atualizada',
    'demanda.removida' => 'Solicitacao removida',
    'demanda.status.aceito' => 'Solicitacao aceita',
    'demanda.status.em_execucao' => 'Servico iniciado',
    'demanda.status.concluido' => 'Servico concluido',
    'avaliacao.criada' => 'Avaliacao registrada',
    _ => 'Atualizacao',
  };

  /// Detalhe legivel a partir do payload, quando houver titulo da demanda.
  String get descricao {
    final t = payload['titulo'];
    if (t is String && t.isNotEmpty) return t;
    return routingKey;
  }

  /// Icone (Material) coerente com o tipo de evento.
  String get categoria {
    if (routingKey.startsWith('candidatura')) return 'proposta';
    if (routingKey.startsWith('demanda')) return 'demanda';
    if (routingKey.startsWith('avaliacao')) return 'avaliacao';
    return 'geral';
  }
}
