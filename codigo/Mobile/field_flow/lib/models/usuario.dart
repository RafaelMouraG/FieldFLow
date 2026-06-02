import 'enums.dart';

/// Usuario autenticado (resposta de GET /auth/me e do registro).
class Usuario {
  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    this.telefone,
  });

  final int id;
  final String nome;
  final String email;
  final TipoUsuario tipo;
  final String? telefone;

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        tipo: TipoUsuario.fromWire(json['tipo'] as String),
        telefone: json['telefone'] as String?,
      );
}
