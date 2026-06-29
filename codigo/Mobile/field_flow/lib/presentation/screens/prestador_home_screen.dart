import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../viewmodels/prestador_home_viewmodel.dart';
import 'demandas_disponiveis_screen.dart';
import 'minhas_candidaturas_screen.dart';
import 'notificacoes_screen.dart';
import 'prestador_perfil_form_screen.dart';
import 'profile_screen.dart';

/// TELA inicial do prestador — Home/dashboard.
///
/// View-only: observa o [PrestadorHomeViewModel], que agrega as demandas
/// disponiveis, candidaturas e servicos em andamento e atualiza por polling.
class PrestadorHomeScreen extends StatelessWidget {
  const PrestadorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrestadorHomeViewModel(context.read<AuthController>()),
      child: const _PrestadorHomeView(),
    );
  }
}

class _PrestadorHomeView extends StatelessWidget {
  const _PrestadorHomeView();

  void _abrir(BuildContext context, Widget tela) {
    final vm = context.read<PrestadorHomeViewModel>();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => tela)).then((_) => vm.carregar());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PrestadorHomeViewModel>();
    final usuario = context.watch<AuthController>().usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FieldFlow • Prestador'),
        actions: [
          _SinoNotificacoes(
            quantidade: vm.notificacoes,
            onTap: () => _abrir(context, const NotificacoesScreen()),
          ),
          IconButton(
            tooltip: 'Meu perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => _abrir(context, const ProfileScreen()),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(context, const DemandasDisponiveisScreen()),
        icon: const Icon(Icons.search),
        label: const Text('Buscar serviços'),
      ),
      body: RefreshIndicator(
        onRefresh: vm.carregar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            Text(
              'Ola, ${usuario?.nome ?? 'prestador'}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Encontre solicitações e acompanhe seus serviços',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            if (!vm.carregando && !vm.perfilAprovado)
              _PerfilPendenteCard(
                perfilStatus: vm.perfil?.status,
                onTap: () =>
                    _abrir(context, const PrestadorPerfilFormScreen()),
              ),
            if (vm.erro != null && vm.disponiveis == 0)
              _ErroCard(mensagem: vm.erro!, onRetry: vm.carregar)
            else
              _Resumo(vm: vm),
            const SizedBox(height: 20),
            _AcaoTile(
              icone: Icons.search,
              titulo: 'Solicitações disponíveis',
              subtitulo: vm.disponiveis > 0
                  ? '${vm.disponiveis} aberta(s) para candidatura'
                  : 'Nenhuma no momento',
              onTap: () => _abrir(context, const DemandasDisponiveisScreen()),
            ),
            _AcaoTile(
              icone: Icons.assignment_turned_in_outlined,
              titulo: 'Minhas candidaturas',
              subtitulo: vm.candidaturasPendentes > 0
                  ? '${vm.candidaturasPendentes} aguardando resposta'
                  : 'Acompanhe suas propostas e serviços',
              onTap: () => _abrir(context, const MinhasCandidaturasScreen()),
            ),
            _AcaoTile(
              icone: Icons.badge_outlined,
              titulo: 'Perfil profissional',
              subtitulo: vm.perfilAprovado
                  ? 'Aprovado • editar dados'
                  : 'Complete para se candidatar',
              onTap: () => _abrir(context, const PrestadorPerfilFormScreen()),
            ),
            _AcaoTile(
              icone: Icons.notifications_outlined,
              titulo: 'Notificações',
              subtitulo: vm.notificacoes > 0
                  ? '${vm.notificacoes} evento(s)'
                  : 'Sem novidades',
              onTap: () => _abrir(context, const NotificacoesScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.vm});
  final PrestadorHomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.carregando && vm.disponiveis == 0 && vm.emAndamento == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Row(
      children: [
        _StatCard(
          rotulo: 'Disponíveis',
          valor: vm.disponiveis,
          cor: Colors.orange,
          icone: Icons.search,
        ),
        const SizedBox(width: 12),
        _StatCard(
          rotulo: 'Candidaturas',
          valor: vm.candidaturasPendentes,
          cor: Colors.blue,
          icone: Icons.assignment_outlined,
        ),
        const SizedBox(width: 12),
        _StatCard(
          rotulo: 'Em andamento',
          valor: vm.emAndamento,
          cor: Colors.purple,
          icone: Icons.agriculture_outlined,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.rotulo,
    required this.valor,
    required this.cor,
    required this.icone,
  });
  final String rotulo;
  final int valor;
  final Color cor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icone, color: cor),
            const SizedBox(height: 8),
            Text(
              '$valor',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcaoTile extends StatelessWidget {
  const _AcaoTile({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(icone, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Aviso de perfil ainda nao aprovado (bloqueia candidaturas no backend).
class _PerfilPendenteCard extends StatelessWidget {
  const _PerfilPendenteCard({required this.perfilStatus, required this.onTap});
  final String? perfilStatus;
  final VoidCallback onTap;

  String get _texto => switch (perfilStatus) {
    'EM_ANALISE' => 'Seu perfil está em análise. Em breve você poderá se '
        'candidatar.',
    'REPROVADO' => 'Seu perfil foi reprovado. Revise e reenvie para se '
        'candidatar.',
    _ => 'Complete seu perfil profissional para poder se candidatar.',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.amber.shade50,
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: Colors.amber),
        title: const Text(
          'Perfil incompleto',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_texto),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SinoNotificacoes extends StatelessWidget {
  const _SinoNotificacoes({required this.quantidade, required this.onTap});
  final int quantidade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notificações',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onTap,
        ),
        if (quantidade > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                quantidade > 99 ? '99+' : '$quantidade',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErroCard extends StatelessWidget {
  const _ErroCard({required this.mensagem, required this.onRetry});
  final String mensagem;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.cloud_off, color: Colors.grey.shade500, size: 40),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
