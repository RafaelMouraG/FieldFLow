import 'enums.dart';

/// Usuario autenticado (resposta de GET /auth/me e do registro).
class Usuario {
  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    this.tipoDocumento,
    this.telefone,
    this.endereco,
    this.enderecoLat,
    this.enderecoLng,
  });

  final int id;
  final String nome;
  final String email;
  final TipoUsuario tipo;
  final TipoDocumento? tipoDocumento;
  final String? telefone;

  // Endereco da fazenda/empresa (uso pratico apenas para clientes CNPJ).
  final String? endereco;
  final double? enderecoLat;
  final double? enderecoLng;

  /// `true` quando o cliente e pessoa juridica (libera o endereco da fazenda).
  bool get ehCnpj => tipoDocumento == TipoDocumento.cnpj;

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as int,
    nome: json['nome'] as String,
    email: json['email'] as String,
    tipo: TipoUsuario.fromWire(json['tipo'] as String),
    tipoDocumento: json['tipo_documento'] != null
        ? TipoDocumento.fromWire(json['tipo_documento'] as String)
        : null,
    telefone: json['telefone'] as String?,
    endereco: json['endereco'] as String?,
    enderecoLat: (json['endereco_lat'] as num?)?.toDouble(),
    enderecoLng: (json['endereco_lng'] as num?)?.toDouble(),
  );
}
