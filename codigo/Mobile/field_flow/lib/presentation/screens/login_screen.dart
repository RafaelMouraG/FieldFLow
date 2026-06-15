import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../state/auth_controller.dart';
import '../viewmodels/login_viewmodel.dart';
import 'register_screen.dart';

/// View do login. Toda a logica vive no [LoginViewModel]; aqui ficam apenas
/// os controllers de texto (detalhe de widget) e a montagem visual.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(context.read<AuthController>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'cliente@fieldflow.dev');
  final _senha = TextEditingController(text: 'senha123');
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    final erro = await context.read<LoginViewModel>().entrar(
      _email.text,
      _senha.text,
    );
    if (erro != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
      );
    }
    // Sucesso: o AuthGate troca de tela ao observar o AuthController.
  }

  @override
  Widget build(BuildContext context) {
    final enviando = context.watch<LoginViewModel>().enviando;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.agriculture,
                      size: 72,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'FieldFlow',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Marketplace de servicos agricolas',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Informe um e-mail valido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senha,
                      obscureText: !_mostrarSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _mostrarSenha = !_mostrarSenha),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Minimo de 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: enviando ? null : _entrar,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: enviando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: enviando
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                      child: const Text('Criar conta de cliente'),
                    ),
                    const Divider(height: 32),
                    const _ServidorTile(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloco recolhivel para inspecionar/alterar a URL da API em tempo de execucao.
/// Util para apontar o app (celular fisico) ao IP da maquina que roda a API.
class _ServidorTile extends StatefulWidget {
  const _ServidorTile();

  @override
  State<_ServidorTile> createState() => _ServidorTileState();
}

class _ServidorTileState extends State<_ServidorTile> {
  late final TextEditingController _url = TextEditingController(
    text: Config.baseUrl,
  );

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    await Config.setBaseUrl(_url.text);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Servidor: ${Config.baseUrl}')));
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      leading: const Icon(Icons.dns_outlined),
      title: const Text('Servidor'),
      subtitle: Text(
        Config.baseUrl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'URL da API',
            hintText: 'http://192.168.0.10:8000',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _salvar, child: const Text('Salvar')),
        ),
      ],
    );
  }
}
