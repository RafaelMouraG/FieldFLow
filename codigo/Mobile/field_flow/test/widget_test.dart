// Smoke test do FieldFlow: sem sessao salva, o app deve abrir na tela de login.
import 'package:field_flow/core/config.dart';
import 'package:field_flow/main.dart';
import 'package:field_flow/state/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('abre na tela de login quando nao ha sessao',
      (WidgetTester tester) async {
    // Sem token salvo -> nao autenticado, sem chamadas de rede.
    SharedPreferences.setMockInitialValues({});
    await Config.load();

    final auth = AuthController();
    await auth.restaurarSessao();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: auth, child: const FieldFlowApp()),
    );
    await tester.pumpAndSettle();

    // Titulo da marca e o botao de entrar estao presentes.
    expect(find.text('FieldFlow'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta de cliente'), findsOneWidget);
  });
}
