import 'enums.dart';

/// Versao reduzida de um usuario visivel a outros (id, nome, tipo).
class UsuarioPublico {
  UsuarioPublico({required this.id, required this.nome, required this.tipo});

  final int id;
  final String nome;
  final TipoUsuario tipo;
}
