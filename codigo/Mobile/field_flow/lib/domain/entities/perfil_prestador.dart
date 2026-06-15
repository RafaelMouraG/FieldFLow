/// Perfil profissional de um prestador (curriculo).
///
/// `notaMedia`/`totalAvaliacoes` so existem depois da Onda de Avaliacoes; ficam
/// nulos/zero enquanto o backend nao os envia.
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
}
