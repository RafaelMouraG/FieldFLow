import 'enums.dart';

/// Solicitacao de servico criada por um cliente.
///
/// Entidade de dominio: pura (sem serializacao). A conversao de/para JSON
/// vive em `data/models/demanda_model.dart`.
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
}
