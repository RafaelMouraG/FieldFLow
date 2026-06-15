import '../../domain/entities/enums.dart';
import '../../domain/entities/usuario_publico.dart';

/// Mapper de (de)serializacao do [UsuarioPublico] (camada de dados).
class UsuarioPublicoModel {
  const UsuarioPublicoModel._();

  static UsuarioPublico fromJson(Map<String, dynamic> json) => UsuarioPublico(
    id: json['id'] as int,
    nome: json['nome'] as String,
    tipo: TipoUsuario.fromWire(json['tipo'] as String),
  );
}
