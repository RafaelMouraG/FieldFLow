import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/enums.dart';
import '../../state/auth_controller.dart';
import '../viewmodels/register_viewmodel.dart';

/// View do cadastro de cliente. Logica no [RegisterViewModel].
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(context.read<AuthController>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _documento = TextEditingController();
  final _senha = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _documento.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    final erro = await context.read<RegisterViewModel>().cadastrar(
      nome: _nome.text,
      email: _email.text,
      senha: _senha.text,
      documento: _documento.text,
      telefone: _telefone.text,
    );
    if (!mounted) return;
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
      );
    } else {
      Navigator.of(context).pop(); // AuthGate troca para o app
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<TipoUsuario>(
                  segments: const [
                    ButtonSegment(
                      value: TipoUsuario.cliente,
                      label: Text('Cliente'),
                      icon: Icon(Icons.agriculture),
                    ),
                    ButtonSegment(
                      value: TipoUsuario.prestador,
                      label: Text('Prestador'),
                      icon: Icon(Icons.handyman),
                    ),
                  ],
                  selected: {vm.tipoUsuario},
                  onSelectionChanged: (s) => vm.setTipoUsuario(s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  vm.isPrestador
                      ? 'Receba solicitações, candidate-se e execute serviços.'
                      : 'Crie solicitações e contrate prestadores.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'E-mail inválido'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
                  ),
                ),
                const SizedBox(height: 16),
                if (vm.isPrestador)
                  // Prestador e sempre pessoa fisica: documento fixo em CPF.
                  TextFormField(
                    controller: _documento,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CPF'),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      return d.length != vm.digitosEsperados
                          ? 'CPF deve ter ${vm.digitosEsperados} digitos'
                          : null;
                    },
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<TipoDocumento>(
                          initialValue: vm.tipoDoc,
                          decoration: const InputDecoration(
                            labelText: 'Documento',
                          ),
                          items: TipoDocumento.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.wire),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              vm.setTipoDoc(v ?? TipoDocumento.cpf),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _documento,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: vm.tipoDoc.wire,
                          ),
                          validator: (v) {
                            final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                            return d.length != vm.digitosEsperados
                                ? '${vm.tipoDoc.wire} deve ter ${vm.digitosEsperados} digitos'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senha,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo de 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: vm.enviando ? null : _cadastrar,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: vm.enviando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cadastrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
