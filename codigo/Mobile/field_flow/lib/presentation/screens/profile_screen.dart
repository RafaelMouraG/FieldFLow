import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/local_selecionado.dart';
import '../../state/auth_controller.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'location_picker_screen.dart';

/// TELA — Meu perfil: edita nome/email/telefone e troca a senha.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(context.read<AuthController>()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _formPerfil = GlobalKey<FormState>();
  final _formSenha = GlobalKey<FormState>();

  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  final _senhaNova = TextEditingController();

  @override
  void initState() {
    super.initState();
    final u = context.read<ProfileViewModel>().usuario;
    _nome = TextEditingController(text: u?.nome ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _telefone = TextEditingController(text: u?.telefone ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _senhaNova.dispose();
    super.dispose();
  }

  void _aviso(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: erro ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _salvarPerfil() async {
    if (!_formPerfil.currentState!.validate()) return;
    final vm = context.read<ProfileViewModel>();
    final erro = await vm.salvar(
      nome: _nome.text.trim(),
      email: _email.text.trim(),
      telefone: _telefone.text.trim(),
    );
    _aviso(erro ?? 'Perfil atualizado!', erro: erro != null);
  }

  /// Abre o mapa para o cliente CNPJ definir o endereco da fazenda. Pre-centra
  /// no endereco ja salvo, se houver. Ao confirmar, persiste no perfil.
  Future<void> _definirEnderecoFazenda() async {
    final vm = context.read<ProfileViewModel>();
    final u = vm.usuario;
    final inicial = (u?.enderecoLat != null && u?.enderecoLng != null)
        ? LatLng(u!.enderecoLat!, u.enderecoLng!)
        : null;

    final r = await Navigator.of(context).push<LocalSelecionado>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          inicial: inicial,
          rotuloInicial: u?.endereco,
          titulo: 'Endereço da fazenda',
        ),
      ),
    );
    if (r == null) return;
    if (r.rotulo.isEmpty) {
      _aviso('Informe um rótulo/endereço para a fazenda.', erro: true);
      return;
    }
    final erro = await vm.salvarEndereco(
      endereco: r.rotulo,
      lat: r.lat,
      lng: r.lng,
    );
    _aviso(erro ?? 'Endereço da fazenda salvo!', erro: erro != null);
  }

  Future<void> _trocarSenha() async {
    if (!_formSenha.currentState!.validate()) return;
    final vm = context.read<ProfileViewModel>();
    final erro = await vm.trocarSenha(_senhaNova.text);
    if (erro == null) {
      _senhaNova.clear();
    }
    _aviso(erro ?? 'Senha alterada!', erro: erro != null);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formPerfil,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dados pessoais',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'E-mail inválido'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: vm.salvando ? null : _salvarPerfil,
                    child: Text(vm.salvando ? 'Salvando...' : 'Salvar dados'),
                  ),
                ),
              ],
            ),
          ),
          if (vm.usuario?.ehCnpj ?? false) ...[
            const Divider(height: 40),
            const Text(
              'Endereço da fazenda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Disponível para clientes CNPJ. Serve de referência e pré-centra '
              'o mapa ao criar uma solicitação.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.agriculture_outlined),
                title: Text(
                  (vm.usuario?.endereco?.isNotEmpty ?? false)
                      ? vm.usuario!.endereco!
                      : 'Nenhum endereço definido',
                ),
                subtitle: (vm.usuario?.enderecoLat != null)
                    ? Text(
                        '${vm.usuario!.enderecoLat!.toStringAsFixed(5)}, '
                        '${vm.usuario!.enderecoLng!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 11),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: vm.salvandoEndereco ? null : _definirEnderecoFazenda,
                icon: const Icon(Icons.map_outlined),
                label: Text(
                  vm.salvandoEndereco
                      ? 'Salvando...'
                      : (vm.usuario?.endereco?.isNotEmpty ?? false)
                      ? 'Atualizar endereço no mapa'
                      : 'Definir endereço no mapa',
                ),
              ),
            ),
          ],
          const Divider(height: 40),
          Form(
            key: _formSenha,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trocar senha',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _senhaNova,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: vm.trocandoSenha ? null : _trocarSenha,
                    child: Text(
                      vm.trocandoSenha ? 'Alterando...' : 'Alterar senha',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
