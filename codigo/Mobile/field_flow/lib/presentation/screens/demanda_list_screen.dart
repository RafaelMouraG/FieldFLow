import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../viewmodels/demanda_list_viewmodel.dart';
import '../widgets/demanda_card.dart';
import 'demanda_detail_screen.dart';
import 'demanda_form_screen.dart';

/// TELA 1 — Listagem das solicitacoes (demandas) do cliente.
///
/// View-only: observa o [DemandaListViewModel], que cuida da carga inicial e do
/// polling periodico (atualizacao assincrona de estado).
class DemandaListScreen extends StatelessWidget {
  const DemandaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DemandaListViewModel(context.read<AuthController>()),
      child: const _DemandaListView(),
    );
  }
}

class _DemandaListView extends StatelessWidget {
  const _DemandaListView();

  Future<void> _abrirCriacao(BuildContext context) async {
    final vm = context.read<DemandaListViewModel>();
    final criada = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const DemandaFormScreen()));
    if (criada == true) vm.carregar();
  }

  void _abrirDetalhe(BuildContext context, int id) {
    final vm = context.read<DemandaListViewModel>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => DemandaDetailScreen(demandaId: id)),
        )
        .then((_) => vm.carregar());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DemandaListViewModel>();
    final usuario = context.watch<AuthController>().usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas solicitacoes'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
        bottom: usuario == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Ola, ${usuario.nome}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirCriacao(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova solicitacao'),
      ),
      body: RefreshIndicator(
        onRefresh: vm.carregar,
        child: _buildBody(context, vm),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DemandaListViewModel vm) {
    if (vm.carregando && vm.demandas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.erro != null && vm.demandas.isEmpty) {
      return _ErroView(mensagem: vm.erro!, onRetry: vm.carregar);
    }
    if (vm.demandas.isEmpty) {
      return const _VazioView();
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: vm.demandas.length,
      itemBuilder: (_, i) => DemandaCard(
        demanda: vm.demandas[i],
        onTap: () => _abrirDetalhe(context, vm.demandas[i].id),
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
        Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Center(child: Text('Nenhuma solicitacao ainda')),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Toque em "Nova solicitacao" para comecar',
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
