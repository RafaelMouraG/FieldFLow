import 'enums.dart';

/// Versao reduzida de um usuario visivel a outros (GET /usuarios/{id}).
/// Omite documento/telefone — so traz o necessario para exibir um prestador.
class UsuarioPublico {
  UsuarioPublico({required this.id, required this.nome, required this.tipo});

  final int id;
  final String nome;
  final TipoUsuario tipo;

  factory UsuarioPublico.fromJson(Map<String, dynamic> json) => UsuarioPublico(
    id: json['id'] as int,
    nome: json['nome'] as String,
    tipo: TipoUsuario.fromWire(json['tipo'] as String),
  );
}
