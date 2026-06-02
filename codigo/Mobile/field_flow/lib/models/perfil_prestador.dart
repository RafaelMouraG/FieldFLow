/// Perfil profissional de um prestador (GET /prestadores/{id}/perfil).
///
/// `notaMedia`/`totalAvaliacoes` so existem depois da Onda de Avaliacoes; sao
/// lidos de forma tolerante (ficam nulos/zero enquanto o backend nao os envia).
class PerfilPrestador {
  PerfilPrestador({
    required this.usuarioId,
    required this.status,
    required this.especialidades,
    required this.regioesAtuacao,
    required this.equipamentosProprios,
    required this.certificacoes,
    this.bio,
    this.anosExperiencia,
    this.cnhCategoria,
    this.notaMedia,
    this.totalAvaliacoes = 0,
  });

  final int usuarioId;
  final String status; // INCOMPLETO | EM_ANALISE | APROVADO | REPROVADO
  final List<String> especialidades;
  final List<String> regioesAtuacao;
  final List<String> equipamentosProprios;
  final List<String> certificacoes;
  final String? bio;
  final int? anosExperiencia;
  final String? cnhCategoria;
  final double? notaMedia;
  final int totalAvaliacoes;

  bool get aprovado => status == 'APROVADO';

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

  factory PerfilPrestador.fromJson(Map<String, dynamic> json) =>
      PerfilPrestador(
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
