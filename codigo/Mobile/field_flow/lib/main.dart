import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
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

/// Decide a tela inicial conforme a sessao: splash enquanto restaura,
/// login quando deslogado, Home quando autenticado. Como observa o
/// [AuthController], a troca login <-> logout e automatica.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (auth.carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.autenticado ? const HomeScreen() : const LoginScreen();
  }
}
