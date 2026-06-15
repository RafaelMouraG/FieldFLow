import '../../domain/entities/perfil_prestador.dart';

/// Mapper de (de)serializacao do [PerfilPrestador] (camada de dados).
class PerfilPrestadorModel {
  const PerfilPrestadorModel._();

  static List<String> _strList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) {
      // certificacoes vem como list de objetos; pega um campo legivel.
      if (e is Map) {
        return (e['nome'] ?? e['titulo'] ?? e.values.first).toString();
      }
      return e.toString();
    }).toList();
  }

  static PerfilPrestador fromJson(Map<String, dynamic> json) => PerfilPrestador(
    usuarioId: json['usuario_id'] as int,
    status: json['status'] as String,
    especialidades: _strList(json['especialidades']),
    regioesAtuacao: _strList(json['regioes_atuacao']),
    equipamentosProprios: _strList(json['equipamentos_proprios']),
    certificacoes: _strList(json['certificacoes']),
    bio: json['bio'] as String?,
    anosExperiencia: json['anos_experiencia'] as int?,
    cnhCategoria: json['cnh_categoria'] as String?,
    notaMedia: (json['nota_media'] as num?)?.toDouble(),
    totalAvaliacoes: (json['total_avaliacoes'] as num?)?.toInt() ?? 0,
  );
}
