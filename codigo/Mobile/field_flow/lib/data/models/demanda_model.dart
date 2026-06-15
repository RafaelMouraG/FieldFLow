import '../../domain/entities/demanda.dart';
import '../../domain/entities/enums.dart';

/// Mapper de (de)serializacao da [Demanda] (camada de dados).
/// Isola o conhecimento do formato JSON do backend fora do dominio.
class DemandaModel {
  const DemandaModel._();

  static Demanda fromJson(Map<String, dynamic> json) => Demanda(
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
