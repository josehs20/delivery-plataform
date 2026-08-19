import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/auth_cubit.dart';
import 'admin_audit_logs_screen.dart';
import 'admin_deliveries_screen.dart';
import 'admin_financial_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_pending_drivers_screen.dart';

/// Painel Administrativo completo — shell responsivo com NavigationRail (telas
/// largas/Web) ou Drawer (telas estreitas/Mobile) e os cinco módulos.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const _titles = [
    'Visão Geral',
    'Aprovação de Motoboys',
    'Gestão de Entregas',
    'Financeiro & Reembolsos',
    'Logs de Auditoria',
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.two_wheeler_outlined,
    Icons.local_shipping_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.receipt_long_outlined,
  ];

  Widget _buildModule() {
    return switch (_selectedIndex) {
      0 => const AdminOverviewScreen(),
      1 => const AdminPendingDriversScreen(),
      2 => const AdminDeliveriesScreen(),
      3 => const AdminFinancialScreen(),
      _ => const AdminAuditLogsScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Admin não volta para Splash/Login pelo botão "Voltar" (guarda de sessão).
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => context.read<AuthCubit>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
              ),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final useRail = constraints.maxWidth >= 900;
            return Row(
              children: [
                if (useRail) _buildRail(context),
                Expanded(child: _buildModule()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) =>
          setState(() => _selectedIndex = index),
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (var i = 0; i < _titles.length; i++)
          NavigationRailDestination(
            icon: Icon(_icons[i]),
            label: Text(_titles[i]),
          ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 48),
                SizedBox(height: 8),
                Text('Painel Administrativo'),
              ],
            ),
          ),
          for (var i = 0; i < _titles.length; i++)
            ListTile(
              selected: _selectedIndex == i,
              leading: Icon(_icons[i]),
              title: Text(_titles[i]),
              onTap: () {
                setState(() => _selectedIndex = i);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
