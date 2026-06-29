import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../viewmodels/demandas_disponiveis_viewmodel.dart';
import '../widgets/demanda_card.dart';
import 'demanda_prestador_detail_screen.dart';

/// TELA — Solicitacoes disponiveis para o prestador se candidatar.
///
/// View-only: observa o [DemandasDisponiveisViewModel], que carrega as demandas
/// PENDENTES e faz polling. Quando surge uma demanda nova, a View mostra um
/// SnackBar (evento one-shot via `takeMensagem`) — notificacao assincrona sem
/// o prestador atualizar a tela.
class DemandasDisponiveisScreen extends StatelessWidget {
  const DemandasDisponiveisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          DemandasDisponiveisViewModel(context.read<AuthController>()),
      child: const _DisponiveisView(),
    );
  }
}

class _DisponiveisView extends StatefulWidget {
  const _DisponiveisView();

  @override
  State<_DisponiveisView> createState() => _DisponiveisViewState();
}

class _DisponiveisViewState extends State<_DisponiveisView> {
  late final DemandasDisponiveisViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<DemandasDisponiveisViewModel>();
    _vm.addListener(_onVmChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    super.dispose();
  }

  /// Reage a eventos transitorios do VM (ex.: chegou demanda nova).
  void _onVmChanged() {
    final msg = _vm.takeMensagem();
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _abrirDetalhe(int id) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => DemandaPrestadorDetailScreen(demandaId: id),
          ),
        )
        .then((_) => _vm.carregar());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DemandasDisponiveisViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitações disponíveis')),
      body: RefreshIndicator(
        onRefresh: vm.carregar,
        child: _buildBody(vm),
      ),
    );
  }

  Widget _buildBody(DemandasDisponiveisViewModel vm) {
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
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: vm.demandas.length,
      itemBuilder: (_, i) => DemandaCard(
        demanda: vm.demandas[i],
        onTap: () => _abrirDetalhe(vm.demandas[i].id),
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
        Icon(Icons.search_off, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Center(child: Text('Nenhuma solicitação disponível')),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Assim que um cliente publicar, ela aparece aqui',
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
