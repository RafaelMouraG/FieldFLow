import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/perfil_prestador.dart';
import '../../state/auth_controller.dart';
import '../viewmodels/prestador_perfil_viewmodel.dart';
import 'prestador_perfil_enviado_screen.dart';

/// TELA — Perfil profissional do prestador (completar/enviar para analise).
///
/// O backend auto-aprova (via worker/MOM) quando ha >= 1 ano de experiencia e
/// >= 1 certificacao. So prestadores APROVADOS conseguem se candidatar.
class PrestadorPerfilFormScreen extends StatelessWidget {
  const PrestadorPerfilFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrestadorPerfilViewModel(context.read<AuthController>()),
      child: const _PerfilFormView(),
    );
  }
}

class _PerfilFormView extends StatefulWidget {
  const _PerfilFormView();

  @override
  State<_PerfilFormView> createState() => _PerfilFormViewState();
}

class _PerfilFormViewState extends State<_PerfilFormView> {
  final _formKey = GlobalKey<FormState>();
  final _bio = TextEditingController();
  final _anos = TextEditingController();
  final _especialidades = TextEditingController();
  final _certificacoes = TextEditingController();
  final _cnh = TextEditingController();
  final _regioes = TextEditingController();
  final _equipamentos = TextEditingController();

  bool _preenchido = false;

  @override
  void dispose() {
    _bio.dispose();
    _anos.dispose();
    _especialidades.dispose();
    _certificacoes.dispose();
    _cnh.dispose();
    _regioes.dispose();
    _equipamentos.dispose();
    super.dispose();
  }

  /// Pre-preenche os campos com o perfil atual (uma vez, apos a carga).
  void _preencher(PerfilPrestador p) {
    if (_preenchido) return;
    _preenchido = true;
    _bio.text = p.bio ?? '';
    _anos.text = (p.anosExperiencia ?? '').toString();
    _especialidades.text = p.especialidades.join(', ');
    _certificacoes.text = p.certificacoes.join(', ');
    _cnh.text = p.cnhCategoria ?? '';
    _regioes.text = p.regioesAtuacao.join(', ');
    _equipamentos.text = p.equipamentosProprios.join(', ');
  }

  List<String> _lista(String v) => v
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<PrestadorPerfilViewModel>();
    final erro = await vm.enviar(
      bio: _bio.text.trim(),
      anosExperiencia: int.tryParse(_anos.text.trim()) ?? 0,
      especialidades: _lista(_especialidades.text),
      certificacoes: _lista(_certificacoes.text),
      cnhCategoria: _cnh.text.trim(),
      regioesAtuacao: _lista(_regioes.text),
      equipamentosProprios: _lista(_equipamentos.text),
    );
    if (!mounted) return;
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
      );
      return;
    }
    // Sucesso: troca esta tela pela confirmação (que retorna ao menu principal).
    final status = context.read<PrestadorPerfilViewModel>().perfil?.status ??
        'EM_ANALISE';
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PrestadorPerfilEnviadoScreen(status: status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PrestadorPerfilViewModel>();
    final perfil = vm.perfil;
    if (perfil != null) _preencher(perfil);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil profissional')),
      body: vm.carregando && perfil == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (perfil != null) _StatusBanner(perfil: perfil),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _anos,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Anos de experiência',
                          helperText: 'Mínimo 1 para aprovação automática',
                        ),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n < 0) return 'Informe um número válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _certificacoes,
                        decoration: const InputDecoration(
                          labelText: 'Certificações (separadas por vírgula)',
                          helperText: 'Mínimo 1 para aprovação automática',
                        ),
                        validator: (v) =>
                            _lista(v ?? '').isEmpty ? 'Informe ao menos uma' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _especialidades,
                        decoration: const InputDecoration(
                          labelText: 'Especialidades (separadas por vírgula)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _regioes,
                        decoration: const InputDecoration(
                          labelText: 'Regiões de atuação (separadas por vírgula)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _equipamentos,
                        decoration: const InputDecoration(
                          labelText: 'Equipamentos próprios (separados por vírgula)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cnh,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Categoria da CNH (opcional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bio,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Sobre você (opcional)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: vm.enviando ? null : _enviar,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: vm.enviando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Enviar para análise'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Faixa com o status atual do perfil (e o motivo, quando reprovado).
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.perfil});
  final PerfilPrestador perfil;

  ({Color cor, IconData icone, String texto}) get _info => switch (perfil.status) {
    'APROVADO' => (
      cor: Colors.green,
      icone: Icons.verified,
      texto: 'Perfil aprovado. Você já pode se candidatar.',
    ),
    'EM_ANALISE' => (
      cor: Colors.blue,
      icone: Icons.hourglass_top,
      texto: 'Perfil em análise. Aguarde a aprovação.',
    ),
    'REPROVADO' => (
      cor: Colors.red,
      icone: Icons.error_outline,
      texto: 'Perfil reprovado. Revise os dados e reenvie.',
    ),
    _ => (
      cor: Colors.amber,
      icone: Icons.info_outline,
      texto: 'Complete os dados abaixo e envie para análise.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final i = _info;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: i.cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: i.cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(i.icone, color: i.cor),
          const SizedBox(width: 10),
          Expanded(child: Text(i.texto)),
        ],
      ),
    );
  }
}
