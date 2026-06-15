import '../../domain/entities/enums.dart';
import '../../domain/entities/usuario.dart';

/// Mapper de (de)serializacao do [Usuario] (camada de dados).
class UsuarioModel {
  const UsuarioModel._();

  static Usuario fromJson(Map<String, dynamic> json) => Usuario(
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
