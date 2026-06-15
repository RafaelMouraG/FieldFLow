import 'enums.dart';

/// Usuario autenticado (sessao).
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
}
