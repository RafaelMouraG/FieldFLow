import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../models/candidatura.dart';
import '../models/demanda.dart';
import '../state/auth_controller.dart';
import '../viewmodels/demanda_detail_viewmodel.dart';
import '../widgets/candidatura_card.dart';
import '../widgets/status_chip.dart';

/// TELA 2 — Detalhe da demanda + propostas (candidaturas) recebidas.
///
/// View-only: observa o [DemandaDetailViewModel], que recarrega demanda e
/// candidaturas por polling. Quando o VM sinaliza uma proposta nova, a View
/// mostra um SnackBar (evento one-shot via `takeMensagem`).
class DemandaDetailScreen extends StatelessWidget {
  const DemandaDetailScreen({super.key, required this.demandaId});
  final int demandaId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          DemandaDetailViewModel(context.read<AuthController>(), demandaId),
      child: const _DemandaDetailView(),
    );
  }
}

class _DemandaDetailView extends StatefulWidget {
  const _DemandaDetailView();

  @override
  State<_DemandaDetailView> createState() => _DemandaDetailViewState();
}

class _DemandaDetailViewState extends State<_DemandaDetailView> {
  late final DemandaDetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<DemandaDetailViewModel>();
    _vm.addListener(_onVmChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    super.dispose();
  }

  /// Reage a eventos transitorios do VM (ex.: chegou proposta nova).
  void _onVmChanged() {
    final msg = _vm.takeMensagem();
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _aceitar(Candidatura c) async {
    final erro = await _vm.aceitar(c);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      erro == null
          ? const SnackBar(content: Text('Proposta aceita!'))
          : SnackBar(
              content: Text(erro), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DemandaDetailViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da solicitacao')),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(DemandaDetailViewModel vm) {
    if (vm.carregando && vm.demanda == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.erro != null && vm.demanda == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.erro!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                  onPressed: () => vm.carregar(),
                  child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    final d = vm.demanda!;
    return RefreshIndicator(
      onRefresh: vm.carregar,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _Cabecalho(demanda: d),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('Propostas (${vm.candidaturas.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                const _PollingBadge(),
              ],
            ),
          ),
          if (vm.candidaturas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Nenhuma proposta ainda.\nAguarde prestadores se candidatarem.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...vm.candidaturas.map((c) => CandidaturaCard(
                  candidatura: c,
                  podeAceitar: vm.podeAceitar,
                  aceitando: vm.aceitandoId == c.id,
                  onAceitar: () => _aceitar(c),
                )),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.demanda});
  final Demanda demanda;

  @override
  Widget build(BuildContext context) {
    final d = demanda;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.titulo,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              DemandaStatusChip(d.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(d.tipoServico, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          Text(d.descricao),
          const SizedBox(height: 16),
          _Linha(Icons.location_on_outlined, 'Origem', d.origem),
          if (d.destino != null && d.destino!.isNotEmpty)
            _Linha(Icons.flag_outlined, 'Destino', d.destino!),
          _Linha(Icons.crop_outlined, 'Area', Fmt.area(d.areaHectares)),
          _Linha(Icons.payments_outlined, 'Pagamento',
              Fmt.pagamento(d.valorRecompensa, d.unidadePagamento)),
          if (d.dataLimite != null)
            _Linha(Icons.event_outlined, 'Data limite', Fmt.data(d.dataLimite)),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.icone, this.rotulo, this.valor);
  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(rotulo,
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

/// Indica visualmente que a tela atualiza sozinha (polling).
class _PollingBadge extends StatelessWidget {
  const _PollingBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.grey.shade400),
        ),
        const SizedBox(width: 6),
        Text('atualizando',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}
