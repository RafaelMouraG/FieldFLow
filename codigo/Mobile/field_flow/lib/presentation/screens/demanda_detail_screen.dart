import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../domain/entities/candidatura.dart';
import '../../domain/entities/demanda.dart';
import '../../domain/entities/enums.dart';
import '../../state/auth_controller.dart';
import '../viewmodels/demanda_detail_viewmodel.dart';
import '../widgets/candidatura_card.dart';
import '../widgets/map_preview.dart';
import '../widgets/rating_stars.dart';
import '../widgets/status_chip.dart';
import 'prestador_profile_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _aceitar(Candidatura c) async {
    final erro = await _vm.aceitar(c);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      erro == null
          ? const SnackBar(content: Text('Proposta aceita!'))
          : SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _concluir() async {
    final erro = await _vm.concluir();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      erro == null
          ? const SnackBar(content: Text('Servico marcado como concluido!'))
          : SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _avaliar() async {
    final r = await showDialog<({int nota, String comentario})>(
      context: context,
      builder: (_) => const _AvaliacaoDialog(),
    );
    if (r == null) return;
    final erro = await _vm.avaliar(r.nota, r.comentario);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      erro == null
          ? const SnackBar(content: Text('Avaliacao enviada. Obrigado!'))
          : SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
    );
  }

  void _abrirPrestador(Candidatura c) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrestadorProfileScreen(
          prestadorId: c.prestadorId,
          podeAceitar:
              _vm.podeAceitar && c.status == StatusCandidatura.pendente,
          onAceitar: () => _aceitar(c),
        ),
      ),
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
                child: const Text('Tentar novamente'),
              ),
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
          _acaoStatus(vm),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Propostas (${vm.candidaturas.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
            ...vm.candidaturas.map(
              (c) => CandidaturaCard(
                candidatura: c,
                podeAceitar: vm.podeAceitar,
                aceitando: vm.aceitandoId == c.id,
                onAceitar: () => _aceitar(c),
                onTap: () => _abrirPrestador(c),
              ),
            ),
        ],
      ),
    );
  }

  /// Acao/contexto conforme o status: aviso quando aceito (aguardando o
  /// prestador iniciar) e botao "Marcar como concluido" quando em execucao.
  Widget _acaoStatus(DemandaDetailViewModel vm) {
    final status = vm.demanda?.status;
    if (status == DemandaStatus.aceito) {
      return const _AvisoStatus(
        icone: Icons.schedule,
        texto: 'Proposta aceita. Aguardando o prestador iniciar o servico.',
      );
    }
    if (status == DemandaStatus.emExecucao) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: vm.concluindo ? null : _concluir,
            icon: vm.concluindo
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              vm.concluindo ? 'Concluindo...' : 'Marcar como concluido',
            ),
          ),
        ),
      );
    }
    if (status == DemandaStatus.concluido) {
      if (vm.jaAvaliada) {
        final a = vm.avaliacao!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Sua avaliacao:  ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    RatingStars(nota: a.nota.toDouble()),
                  ],
                ),
                if (a.comentario != null && a.comentario!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(a.comentario!),
                ],
              ],
            ),
          ),
        );
      }
      if (vm.podeAvaliar) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: vm.avaliando ? null : _avaliar,
              icon: const Icon(Icons.star_outline),
              label: Text(vm.avaliando ? 'Enviando...' : 'Avaliar prestador'),
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}

/// Dialog de avaliacao: estrelas (1..5) + comentario opcional.
class _AvaliacaoDialog extends StatefulWidget {
  const _AvaliacaoDialog();

  @override
  State<_AvaliacaoDialog> createState() => _AvaliacaoDialogState();
}

class _AvaliacaoDialogState extends State<_AvaliacaoDialog> {
  int _nota = 5;
  final _comentario = TextEditingController();

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Avaliar prestador'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingInput(nota: _nota, onChanged: (n) => setState(() => _nota = n)),
          const SizedBox(height: 8),
          TextField(
            controller: _comentario,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop((nota: _nota, comentario: _comentario.text.trim())),
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}

/// Faixa informativa de status (sem acao).
class _AvisoStatus extends StatelessWidget {
  const _AvisoStatus({required this.icone, required this.texto});
  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icone, size: 18, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
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
                child: Text(
                  d.titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          _Linha(
            Icons.payments_outlined,
            'Pagamento',
            Fmt.pagamento(d.valorRecompensa, d.unidadePagamento),
          ),
          if (d.dataLimite != null)
            _Linha(Icons.event_outlined, 'Data limite', Fmt.data(d.dataLimite)),
          if (d.temLocalizacao) ...[
            const SizedBox(height: 16),
            MapPreview(lat: d.origemLat!, lng: d.origemLng!, rotulo: d.origem),
          ],
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

/// Indica que a tela atualiza sozinha (polling). O spinner so aparece enquanto
/// um refresh esta de fato em andamento; no restante mostra um icone estatico.
class _PollingBadge extends StatelessWidget {
  const _PollingBadge();

  @override
  Widget build(BuildContext context) {
    final atualizando = context.select<DemandaDetailViewModel, bool>(
      (vm) => vm.atualizando,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: atualizando
              ? CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.shade400,
                )
              : Icon(Icons.autorenew, size: 12, color: Colors.grey.shade400),
        ),
        const SizedBox(width: 6),
        Text(
          atualizando ? 'atualizando' : 'atualiza automaticamente',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
