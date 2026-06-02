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
  final double? valorRecompensa;
  final DateTime? dataLimite;
  final int? prestadorId;

  factory Demanda.fromJson(Map<String, dynamic> json) => Demanda(
        id: json['id'] as int,
        clienteId: json['cliente_id'] as int,
        titulo: json['titulo'] as String,
        descricao: json['descricao'] as String,
        origem: json['origem'] as String,
        areaHectares: (json['area_hectares'] as num).toDouble(),
        unidadePagamento:
            UnidadePagamento.fromWire(json['unidade_pagamento'] as String),
        tipoServico: json['tipo_servico'] as String,
        status: DemandaStatus.fromWire(json['status'] as String),
        destino: json['destino'] as String?,
        valorRecompensa: (json['valor_recompensa'] as num?)?.toDouble(),
        dataLimite: json['data_limite'] != null
            ? DateTime.tryParse(json['data_limite'] as String)
            : null,
        prestadorId: json['prestador_id'] as int?,
      );
}
