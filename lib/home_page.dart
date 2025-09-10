import 'package:flutter/material.dart';

import 'package:gestr/app/relationships/clients/application/view/clients_section.dart';
import 'package:gestr/app/tax/application/view/tax_summary_page.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
import 'package:gestr/app/dashboard/dasboard_page.dart';
import 'package:gestr/core/auth/application/viewmodels/profile_completion_viewmodel.dart';
import 'package:gestr/core/auth/application/widgets/custom_bottom_navbar.dart';
import 'package:gestr/app/invoices/application/view/invoices_page.dart';
import 'package:gestr/app/incomes/application/view/incomes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with ProfileCompletionViewmodelMixin {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    const IncomesPage(),
    const InvoicesPage(),
    const TaxSummaryPage(),
    const ClientsSection(),
    const SettingsPage(),
  ];

  final List<IconData> _icons = [
    Icons.dashboard,
    Icons.trending_up,
    Icons.receipt_long,
    Icons.pie_chart,
    Icons.people,
  ];

  final List<String> _labels = [
    'Inicio',
    'Ingresos',
    'Facturas',
    'Fiscalidad',
    'Relaciones',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: isDark ? const DialogBackground() : const BackgroundLight(),
        ),
        SafeArea(
          child: Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color:
                        isDark
                            ? Colors.tealAccent.withValues(alpha: 0.8)
                            : Colors.purpleAccent.withValues(alpha: 0.8),
                  ),
                  onPressed: () {
                    signOut();
                  },
                ),
              ],
            ),
            body: _pages[_currentIndex],
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: _currentIndex,
              icons: _icons,
              labels: _labels,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ),
        ),
      ],
    );
  }
}

// class TaxSummaryPage extends StatelessWidget {
//   const TaxSummaryPage({super.key});

//   @override
//   Widget build(BuildContext context) =>
//       const Center(child: Text('Resumen Fiscal'));
// }

// class ClientsPage extends StatelessWidget {
//   const ClientsPage({super.key});

//   @override
//   Widget build(BuildContext context) => const Center(child: Text('Clientes'));
// }

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Ajustes'));
}
