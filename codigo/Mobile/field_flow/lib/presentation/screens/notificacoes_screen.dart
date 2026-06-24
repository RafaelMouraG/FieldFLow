import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../domain/entities/notificacao.dart';
import '../../state/auth_controller.dart';
import '../viewmodels/notificacoes_viewmodel.dart';

/// TELA — Feed de notificacoes (eventos do usuario). Atualiza por polling.
class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificacoesViewModel(context.read<AuthController>()),
      child: const _NotificacoesView(),
    );
  }
}

class _NotificacoesView extends StatelessWidget {
  const _NotificacoesView();

  IconData _icone(Notificacao n) => switch (n.categoria) {
    'proposta' => Icons.handshake_outlined,
    'demanda' => Icons.assignment_outlined,
    'avaliacao' => Icons.star_outline,
    _ => Icons.notifications_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificacoesViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notificacoes')),
      body: RefreshIndicator(onRefresh: vm.carregar, child: _buildBody(vm)),
    );
  }

  Widget _buildBody(NotificacoesViewModel vm) {
    if (vm.carregando && vm.itens.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.erro != null && vm.itens.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(vm.erro!, textAlign: TextAlign.center),
          ),
        ],
      );
    }
    if (vm.itens.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.notifications_none, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Center(child: Text('Nenhuma notificacao ainda')),
        ],
      );
    }
    return ListView.separated(
      itemCount: vm.itens.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final n = vm.itens[i];
        return ListTile(
          // Nao lidas ficam destacadas com um leve realce de fundo.
          tileColor: n.lida ? null : Colors.blue.withValues(alpha: 0.06),
          leading: CircleAvatar(child: Icon(_icone(n))),
          title: Text(
            n.titulo,
            style: TextStyle(
              fontWeight: n.lida ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
          subtitle: Text(n.descricao),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!n.lida)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                Fmt.dataHora(n.criadoEm),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }
}
