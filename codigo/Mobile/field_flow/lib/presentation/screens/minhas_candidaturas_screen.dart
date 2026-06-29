import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../domain/entities/candidatura.dart';
import '../../domain/entities/demanda.dart';
import '../../state/auth_controller.dart';
import '../viewmodels/minhas_candidaturas_viewmodel.dart';
import '../widgets/demanda_card.dart';
import '../widgets/status_chip.dart';
import 'demanda_prestador_detail_screen.dart';

/// TELA — Acompanhamento do prestador: servicos em andamento + candidaturas.
///
/// View-only: observa o [MinhasCandidaturasViewModel] (carga inicial + polling).
class MinhasCandidaturasScreen extends StatelessWidget {
  const MinhasCandidaturasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          MinhasCandidaturasViewModel(context.read<AuthController>()),
      child: const _AcompanhamentoView(),
    );
  }
}

class _AcompanhamentoView extends StatelessWidget {
  const _AcompanhamentoView();

  void _abrirDetalhe(BuildContext context, int id) {
    final vm = context.read<MinhasCandidaturasViewModel>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => DemandaPrestadorDetailScreen(demandaId: id),
          ),
        )
        .then((_) => vm.carregar());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MinhasCandidaturasViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas candidaturas')),
      body: RefreshIndicator(
        onRefresh: vm.carregar,
        child: _buildBody(context, vm),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MinhasCandidaturasViewModel vm) {
    if (vm.carregando && vm.candidaturas.isEmpty && vm.emAndamento.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.erro != null && vm.candidaturas.isEmpty && vm.emAndamento.isEmpty) {
      return _ErroView(mensagem: vm.erro!, onRetry: vm.carregar);
    }
    if (vm.candidaturas.isEmpty && vm.emAndamento.isEmpty) {
      return const _VazioView();
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        if (vm.emAndamento.isNotEmpty) ...[
          const _Secao('Serviços em andamento'),
          ...vm.emAndamento.map(
            (d) => DemandaCard(
              demanda: d,
              onTap: () => _abrirDetalhe(context, d.id),
            ),
          ),
        ],
        if (vm.candidaturas.isNotEmpty) ...[
          const _Secao('Minhas propostas'),
          ...vm.candidaturas.map(
            (c) => _CandidaturaTile(
              candidatura: c,
              demanda: vm.demandaDe(c),
              onTap: () => _abrirDetalhe(context, c.demandaId),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        titulo,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Cartao de uma candidatura (proposta) do prestador, com o titulo da demanda
/// (quando disponivel) e o status da proposta.
class _CandidaturaTile extends StatelessWidget {
  const _CandidaturaTile({
    required this.candidatura,
    required this.demanda,
    required this.onTap,
  });

  final Candidatura candidatura;
  final Demanda? demanda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = candidatura;
    final titulo = demanda?.titulo ?? 'Solicitação #${c.demandaId}';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Proposta: ${Fmt.dinheiro(c.valorProposto)} • '
          '${Fmt.dataHora(c.criadoEm)}',
        ),
        trailing: CandidaturaStatusChip(c.status),
        onTap: onTap,
      ),
    );
  }
}

class _VazioView extends StatelessWidget {
  const _VazioView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.assignment_outlined, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Center(child: Text('Você ainda não se candidatou')),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Busque solicitações disponíveis para começar',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}

class _ErroView extends StatelessWidget {
  const _ErroView({required this.mensagem, required this.onRetry});
  final String mensagem;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(mensagem, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }
}
