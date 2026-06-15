import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../viewmodels/prestador_profile_viewmodel.dart';
import '../widgets/rating_stars.dart';

/// TELA — Perfil profissional de um prestador (visao do cliente).
///
/// Quando aberta a partir de uma proposta pendente, recebe um callback
/// [onAceitar] para o cliente aceitar sem voltar para o detalhe.
class PrestadorProfileScreen extends StatelessWidget {
  const PrestadorProfileScreen({
    super.key,
    required this.prestadorId,
    this.onAceitar,
    this.podeAceitar = false,
  });

  final int prestadorId;
  final VoidCallback? onAceitar;
  final bool podeAceitar;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrestadorProfileViewModel(
        context.read<AuthController>(),
        prestadorId,
      ),
      child: _PrestadorProfileView(
        prestadorId: prestadorId,
        onAceitar: onAceitar,
        podeAceitar: podeAceitar,
      ),
    );
  }
}

class _PrestadorProfileView extends StatelessWidget {
  const _PrestadorProfileView({
    required this.prestadorId,
    required this.onAceitar,
    required this.podeAceitar,
  });

  final int prestadorId;
  final VoidCallback? onAceitar;
  final bool podeAceitar;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PrestadorProfileViewModel>();
    final titulo = (vm.nome != null && vm.nome!.isNotEmpty)
        ? vm.nome!
        : 'Prestador #$prestadorId';
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do prestador')),
      bottomNavigationBar: (podeAceitar && onAceitar != null)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () {
                    onAceitar!();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Aceitar proposta deste prestador'),
                ),
              ),
            )
          : null,
      body: _buildBody(context, vm, titulo),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PrestadorProfileViewModel vm,
    String titulo,
  ) {
    if (vm.carregando && vm.perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.erro != null && vm.perfil == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.erro!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: vm.carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final p = vm.perfil!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(titulo.characters.first.toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (p.notaMedia != null)
                    RatingStars(nota: p.notaMedia!, total: p.totalAvaliacoes)
                  else
                    Text(
                      'Sem avaliacoes ainda',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (p.bio != null && p.bio!.isNotEmpty) ...[
          _Secao('Sobre'),
          Text(p.bio!),
          const SizedBox(height: 16),
        ],
        if (p.anosExperiencia != null)
          _LinhaInfo(
            Icons.workspace_premium_outlined,
            'Experiencia',
            '${p.anosExperiencia} ano(s)',
          ),
        if (p.cnhCategoria != null && p.cnhCategoria!.isNotEmpty)
          _LinhaInfo(Icons.badge_outlined, 'CNH', p.cnhCategoria!),
        const SizedBox(height: 8),
        if (p.especialidades.isNotEmpty) ...[
          _Secao('Especialidades'),
          _Chips(p.especialidades),
          const SizedBox(height: 16),
        ],
        if (p.equipamentosProprios.isNotEmpty) ...[
          _Secao('Equipamentos'),
          _Chips(p.equipamentosProprios),
          const SizedBox(height: 16),
        ],
        if (p.regioesAtuacao.isNotEmpty) ...[
          _Secao('Regioes de atuacao'),
          _Chips(p.regioesAtuacao),
          const SizedBox(height: 16),
        ],
        if (p.certificacoes.isNotEmpty) ...[
          _Secao('Certificacoes'),
          _Chips(p.certificacoes),
          const SizedBox(height: 16),
        ],
        if (vm.avaliacoes.isNotEmpty) ...[
          _Secao('Avaliacoes (${vm.avaliacoes.length})'),
          ...vm.avaliacoes.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStars(nota: a.nota.toDouble()),
                  if (a.comentario != null && a.comentario!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(a.comentario!),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      titulo,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    ),
  );
}

class _Chips extends StatelessWidget {
  const _Chips(this.itens);
  final List<String> itens;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: itens.map((e) => Chip(label: Text(e))).toList(),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  const _LinhaInfo(this.icone, this.rotulo, this.valor);
  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icone, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              rotulo,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}
