import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/prestador_home_screen.dart';
import 'state/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR'); // formatacao de datas/moeda
  await Config.load(); // restaura URL do servidor salva

  final auth = AuthController();
  await auth.restaurarSessao(); // tenta reaproveitar um token salvo

  runApp(
    ChangeNotifierProvider.value(value: auth, child: const FieldFlowApp()),
  );
}

class FieldFlowApp extends StatelessWidget {
  const FieldFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

/// Decide a tela inicial conforme a sessao: splash enquanto restaura, login
/// quando deslogado e, quando autenticado, roteia por papel — Home do prestador
/// para prestadores e Home do cliente para clientes. Como observa o
/// [AuthController], as trocas login <-> logout e a escolha de papel sao
/// automaticas.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (auth.carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.autenticado) return const LoginScreen();
    return auth.isPrestador
        ? const PrestadorHomeScreen()
        : const HomeScreen();
  }
}
