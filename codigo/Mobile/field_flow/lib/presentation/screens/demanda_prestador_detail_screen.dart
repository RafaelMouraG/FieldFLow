import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../domain/entities/demanda.dart';
import '../../state/auth_controller.dart';
import '../viewmodels/demanda_prestador_detail_viewmodel.dart';
import '../widgets/map_preview.dart';
import '../widgets/status_chip.dart';

/// TELA — Detalhe de uma solicitacao na visao do prestador.
///
/// Permite candidatar-se (com valor proposto + mensagem), cancelar a propria
/// candidatura e, quando a demanda foi atribuida a ele, iniciar a execucao.
/// Observa o [DemandaPrestadorDetailViewModel] (polling).
class DemandaPrestadorDetailScreen extends StatelessWidget {
  const DemandaPrestadorDetailScreen({super.key, required this.demandaId});
  final int demandaId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DemandaPrestadorDetailViewModel(
        context.read<AuthController>(),
        demandaId,
      ),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView();

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  Future<void> _candidatar() async {
    final vm = context.read<DemandaPrestadorDetailViewModel>();
    final r = await showDialog<({String mensagem, double? valor})>(
      context: context,
      builder: (_) => const _CandidaturaDialog(),
    );
    if (r == null) return;
    final erro = await vm.candidatar(
      mensagem: r.mensagem,
      valorProposto: r.valor,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      erro == null
          ? const SnackBar(content: Text('Candidatura enviada!'))
          : SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _cancelar() async {
    final vm = context.read<DemandaPrestadorDetailViewModel>();
    final erro = await vm.cancelar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      erro == null
          ? const SnackBar(content: Text('Candidatura cancelada.'))
          : SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _iniciar() async {
    final vm = context.read<DemandaPrestadorDetailViewModel>();
    final erro = await vm.iniciarExecucao();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      erro == null
          ? const SnackBar(content: Text('Serviço iniciado!'))
          : SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DemandaPrestadorDetailViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da solicitação')),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(DemandaPrestadorDetailViewModel vm) {
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
          _AcaoPrestador(vm: vm, onCandidatar: _candidatar, onCancelar: _cancelar, onIniciar: _iniciar),
        ],
      ),
    );
  }
}

/// Bloco de acao/contexto conforme o estado da demanda e da minha candidatura.
class _AcaoPrestador extends StatelessWidget {
  const _AcaoPrestador({
    required this.vm,
    required this.onCandidatar,
    required this.onCancelar,
    required this.onIniciar,
  });

  final DemandaPrestadorDetailViewModel vm;
  final VoidCallback onCandidatar;
  final VoidCallback onCancelar;
  final VoidCallback onIniciar;

  @override
  Widget build(BuildContext context) {
    final c = vm.minhaCandidatura;
    final children = <Widget>[];

    if (c != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              const Text(
                'Sua candidatura:  ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              CandidaturaStatusChip(c.status),
              const Spacer(),
              Text('Proposta: ${Fmt.dinheiro(c.valorProposto)}'),
            ],
          ),
        ),
      );
    }

    if (vm.podeCandidatar) {
      children.add(
        _BotaoLargo(
          onPressed: vm.enviando ? null : onCandidatar,
          carregando: vm.enviando,
          icone: Icons.how_to_reg,
          texto: 'Candidatar-se',
        ),
      );
    } else if (vm.podeCancelar) {
      children.add(
        _BotaoLargo(
          onPressed: vm.enviando ? null : onCancelar,
          carregando: vm.enviando,
          icone: Icons.cancel_outlined,
          texto: 'Cancelar candidatura',
          tonal: true,
        ),
      );
    } else if (vm.podeIniciar) {
      children.add(
        const _Aviso(
          cor: Colors.green,
          icone: Icons.check_circle_outline,
          texto: 'Sua proposta foi aceita! Inicie o serviço quando começar.',
        ),
      );
      children.add(
        _BotaoLargo(
          onPressed: vm.enviando ? null : onIniciar,
          carregando: vm.enviando,
          icone: Icons.play_arrow,
          texto: 'Iniciar execução',
        ),
      );
    } else if (vm.emExecucaoPorMim) {
      children.add(
        const _Aviso(
          cor: Colors.purple,
          icone: Icons.agriculture_outlined,
          texto: 'Serviço em execução. Aguardando o cliente confirmar a '
              'conclusão.',
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _BotaoLargo extends StatelessWidget {
  const _BotaoLargo({
    required this.onPressed,
    required this.carregando,
    required this.icone,
    required this.texto,
    this.tonal = false,
  });

  final VoidCallback? onPressed;
  final bool carregando;
  final IconData icone;
  final String texto;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final icon = carregando
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icone);
    final label = Text(carregando ? 'Enviando...' : texto);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: tonal
          ? FilledButton.tonalIcon(onPressed: onPressed, icon: icon, label: label)
          : FilledButton.icon(onPressed: onPressed, icon: icon, label: label),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.cor, required this.icone, required this.texto});
  final Color cor;
  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icone, size: 18, color: cor),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
      ),
    );
  }
}

/// Dialog da candidatura: valor proposto (opcional) + mensagem (opcional).
class _CandidaturaDialog extends StatefulWidget {
  const _CandidaturaDialog();

  @override
  State<_CandidaturaDialog> createState() => _CandidaturaDialogState();
}

class _CandidaturaDialogState extends State<_CandidaturaDialog> {
  final _valor = TextEditingController();
  final _mensagem = TextEditingController();

  @override
  void dispose() {
    _valor.dispose();
    _mensagem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Candidatar-se'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _valor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor proposto (opcional)',
              prefixText: r'R$ ',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _mensagem,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Mensagem ao cliente (opcional)',
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
          onPressed: () {
            final txt = _valor.text.trim().replaceAll(',', '.');
            final valor = txt.isEmpty ? null : double.tryParse(txt);
            Navigator.of(context).pop(
              (mensagem: _mensagem.text.trim(), valor: valor),
            );
          },
          child: const Text('Enviar'),
        ),
      ],
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
          _Linha(Icons.crop_outlined, 'Área', Fmt.area(d.areaHectares)),
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
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
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
