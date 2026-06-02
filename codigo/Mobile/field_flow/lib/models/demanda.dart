import 'enums.dart';

/// Solicitacao de servico criada por um cliente (DemandaResponse no backend).
class Demanda {
  Demanda({
    required this.id,
    required this.clienteId,
    required this.titulo,
    required this.descricao,
    required this.origem,
    required this.areaHectares,
    required this.unidadePagamento,
    required this.tipoServico,
    required this.status,
    this.destino,
    this.origemLat,
    this.origemLng,
    this.destinoLat,
    this.destinoLng,
    this.valorRecompensa,
    this.dataLimite,
    this.prestadorId,
  });

  final int id;
  final int clienteId;
  final String titulo;
  final String descricao;
  final String origem;
  final double areaHectares;
  final UnidadePagamento unidadePagamento;
  final String tipoServico;
  final DemandaStatus status;
  final String? destino;
  final double? origemLat;
  final double? origemLng;
  final double? destinoLat;
  final double? destinoLng;
  final double? valorRecompensa;
  final DateTime? dataLimite;
  final int? prestadorId;

  /// `true` quando ha coordenadas do local da tarefa (origem) para o mapa.
  bool get temLocalizacao => origemLat != null && origemLng != null;

  factory Demanda.fromJson(Map<String, dynamic> json) => Demanda(
    id: json['id'] as int,
    clienteId: json['cliente_id'] as int,
    titulo: json['titulo'] as String,
    descricao: json['descricao'] as String,
    origem: json['origem'] as String,
    areaHectares: (json['area_hectares'] as num).toDouble(),
    unidadePagamento: UnidadePagamento.fromWire(
      json['unidade_pagamento'] as String,
    ),
    tipoServico: json['tipo_servico'] as String,
    status: DemandaStatus.fromWire(json['status'] as String),
    destino: json['destino'] as String?,
    origemLat: (json['origem_lat'] as num?)?.toDouble(),
    origemLng: (json['origem_lng'] as num?)?.toDouble(),
    destinoLat: (json['destino_lat'] as num?)?.toDouble(),
    destinoLng: (json['destino_lng'] as num?)?.toDouble(),
    valorRecompensa: (json['valor_recompensa'] as num?)?.toDouble(),
    dataLimite: json['data_limite'] != null
        ? DateTime.tryParse(json['data_limite'] as String)
        : null,
    prestadorId: json['prestador_id'] as int?,
  );
}
