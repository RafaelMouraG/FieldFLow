/// Evento registrado para o usuario (feed de notificacoes).
///
/// O backend grava o evento cru (routing_key + payload da MOM); a traducao
/// para um texto amigavel em pt-BR fica nos getters [titulo]/[descricao].
class Notificacao {
  Notificacao({
    required this.id,
    required this.eventType,
    required this.routingKey,
    required this.payload,
    required this.criadoEm,
    this.lida = false,
  });

  final int id;
  final String eventType;
  final String routingKey;
  final Map<String, dynamic> payload;
  final DateTime criadoEm;

  /// Se o usuario ja visualizou esta notificacao (marca d'agua no backend).
  final bool lida;

  /// Titulo curto conforme a routing key do evento.
  String get titulo => switch (routingKey) {
    'candidatura.criada' => 'Nova proposta recebida',
    'candidatura.aceita' => 'Proposta aceita',
    'candidatura.rejeitada' => 'Proposta recusada',
    'candidatura.cancelada' => 'Proposta cancelada',
    'demanda.criada' => 'Solicitação criada',
    'demanda.atualizada' => 'Solicitação atualizada',
    'demanda.removida' => 'Solicitação removida',
    'demanda.status.aceito' => 'Solicitação aceita',
    'demanda.status.em_execucao' => 'Serviço iniciado',
    'demanda.status.concluido' => 'Serviço concluído',
    'avaliacao.criada' => 'Avaliação registrada',
    _ => 'Atualização',
  };

  /// Detalhe legivel a partir do payload, quando houver titulo da demanda.
  String get descricao {
    final t = payload['titulo'];
    if (t is String && t.isNotEmpty) return t;
    return routingKey;
  }

  /// Categoria (para escolher o icone) coerente com o tipo de evento.
  String get categoria {
    if (routingKey.startsWith('candidatura')) return 'proposta';
    if (routingKey.startsWith('demanda')) return 'demanda';
    if (routingKey.startsWith('avaliacao')) return 'avaliacao';
    return 'geral';
  }
}
