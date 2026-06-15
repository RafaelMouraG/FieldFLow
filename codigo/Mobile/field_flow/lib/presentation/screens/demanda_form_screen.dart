import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../models/enums.dart';
import '../models/local_selecionado.dart';
import '../state/auth_controller.dart';
import '../viewmodels/demanda_form_viewmodel.dart';
import 'location_picker_screen.dart';

/// TELA 3 — Criacao de uma nova solicitacao (acao principal do cliente).
///
/// View-only: a logica (POST /demandas, regra de valor x unidade) vive no
/// [DemandaFormViewModel]. Os `TextEditingController` ficam na View.
class DemandaFormScreen extends StatelessWidget {
  const DemandaFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DemandaFormViewModel(context.read<AuthController>()),
      child: const _DemandaFormView(),
    );
  }
}

class _DemandaFormView extends StatefulWidget {
  const _DemandaFormView();

  @override
  State<_DemandaFormView> createState() => _DemandaFormViewState();
}

class _DemandaFormViewState extends State<_DemandaFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _origem = TextEditingController();
  final _destino = TextEditingController();
  final _tipoServico = TextEditingController();
  final _area = TextEditingController();
  final _valor = TextEditingController();

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _origem.dispose();
    _destino.dispose();
    _tipoServico.dispose();
    _area.dispose();
    _valor.dispose();
    super.dispose();
  }

  double? _parseNum(String s) =>
      double.tryParse(s.trim().replaceAll('.', '').replaceAll(',', '.'));

  Future<void> _escolherData() async {
    final vm = context.read<DemandaFormViewModel>();
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: vm.dataLimite ?? hoje,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 365 * 2)),
    );
    if (escolhida != null) vm.setDataLimite(escolhida);
  }

  /// Abre o seletor de local no mapa. Pre-centra em: coordenada ja marcada >
  /// endereco da fazenda (cliente CNPJ) > centro padrao. Ao confirmar, guarda
  /// as coordenadas no VM e usa o rotulo no campo de texto.
  Future<void> _marcarLocal({required bool origem}) async {
    final vm = context.read<DemandaFormViewModel>();
    final campo = origem ? _origem : _destino;

    LatLng? inicial;
    if (origem && vm.origemMarcada) {
      inicial = LatLng(vm.origemLat!, vm.origemLng!);
    } else if (!origem && vm.destinoMarcado) {
      inicial = LatLng(vm.destinoLat!, vm.destinoLng!);
    } else if (vm.fazendaLat != null && vm.fazendaLng != null) {
      inicial = LatLng(vm.fazendaLat!, vm.fazendaLng!);
    }

    final r = await Navigator.of(context).push<LocalSelecionado>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          inicial: inicial,
          rotuloInicial: campo.text.isNotEmpty
              ? campo.text
              : vm.fazendaEndereco,
          titulo: origem ? 'Local da tarefa' : 'Destino',
        ),
      ),
    );
    if (r == null) return;
    if (origem) {
      vm.setOrigemCoord(r.lat, r.lng);
    } else {
      vm.setDestinoCoord(r.lat, r.lng);
    }
    if (r.rotulo.isNotEmpty) campo.text = r.rotulo;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final erro = await context.read<DemandaFormViewModel>().salvar(
      titulo: _titulo.text,
      descricao: _descricao.text,
      origem: _origem.text,
      destino: _destino.text,
      areaHectares: _parseNum(_area.text) ?? 0,
      tipoServico: _tipoServico.text,
      valorRecompensa: _parseNum(_valor.text),
    );
    if (!mounted) return;
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
      );
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DemandaFormViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nova solicitacao')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titulo,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Titulo',
                    hintText: 'Ex.: Pulverizacao de soja',
                  ),
                  validator: _obrigatorio,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tipoServico,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de servico',
                    hintText: 'Ex.: Pulverizacao, Colheita, Transporte',
                  ),
                  validator: _obrigatorio,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricao,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descricao',
                    alignLabelWithHint: true,
                  ),
                  validator: _obrigatorio,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _origem,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Origem / local',
                    hintText: 'Ex.: Fazenda Boa Vista, Uberaba-MG',
                  ),
                  validator: _obrigatorio,
                ),
                const SizedBox(height: 8),
                _MapaTile(
                  marcado: vm.origemMarcada,
                  resumo: vm.origemResumo,
                  rotulo: 'Marcar local da tarefa no mapa',
                  onTap: () => _marcarLocal(origem: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destino,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Destino (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                _MapaTile(
                  marcado: vm.destinoMarcado,
                  resumo: vm.destinoResumo,
                  rotulo: 'Marcar destino no mapa (opcional)',
                  onTap: () => _marcarLocal(origem: false),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _area,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Area (hectares)',
                    suffixText: 'ha',
                  ),
                  validator: (v) {
                    final n = _parseNum(v ?? '');
                    if (n == null || n <= 0) return 'Informe uma area valida';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UnidadePagamento>(
                  initialValue: vm.unidade,
                  decoration: const InputDecoration(
                    labelText: 'Forma de pagamento',
                  ),
                  items: UnidadePagamento.values
                      .map(
                        (u) => DropdownMenuItem(value: u, child: Text(u.label)),
                      )
                      .toList(),
                  onChanged: (v) => vm.setUnidade(v ?? UnidadePagamento.fixo),
                ),
                const SizedBox(height: 16),
                if (vm.exigeValor)
                  TextFormField(
                    controller: _valor,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                    ),
                    validator: (v) {
                      if (!vm.exigeValor) return null;
                      final n = _parseNum(v ?? '');
                      if (n == null || n < 0) return 'Informe um valor valido';
                      return null;
                    },
                  ),
                if (vm.exigeValor) const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Data limite (opcional)'),
                  subtitle: Text(
                    vm.dataLimite == null
                        ? 'Sem prazo'
                        : Fmt.data(vm.dataLimite),
                  ),
                  trailing: vm.dataLimite == null
                      ? const Icon(Icons.chevron_right)
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => vm.setDataLimite(null),
                        ),
                  onTap: _escolherData,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: vm.enviando ? null : _salvar,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: vm.enviando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publicar solicitacao'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _obrigatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obrigatorio' : null;
}

/// Botao que abre o mapa e mostra se o local ja foi marcado (com as coords).
class _MapaTile extends StatelessWidget {
  const _MapaTile({
    required this.marcado,
    required this.resumo,
    required this.rotulo,
    required this.onTap,
  });

  final bool marcado;
  final String? resumo;
  final String rotulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        side: BorderSide(color: marcado ? cor : Colors.grey.shade400),
      ),
      icon: Icon(
        marcado ? Icons.check_circle : Icons.add_location_alt_outlined,
        color: marcado ? cor : Colors.grey.shade600,
      ),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(marcado ? 'Local marcado' : rotulo),
          if (marcado && resumo != null)
            Text(
              resumo!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }
}
