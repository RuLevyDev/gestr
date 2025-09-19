import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:gestr/domain/repositories/invoice/invoice_reposiroty.dart';
import 'package:gestr/domain/repositories/user/self_employed_repository.dart';
import 'package:gestr/domain/usecases/sii/sii_usecases.dart';

import 'package:gestr/app/relationships/relationships_page.dart';
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
    const RelationshipsPage(),
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
                  tooltip: 'Exportar SII',
                  icon: Icon(
                    Icons.file_download_outlined,
                    color:
                        isDark
                            ? Colors.tealAccent.withValues(alpha: 0.8)
                            : Colors.purpleAccent.withValues(alpha: 0.8),
                  ),
                  onPressed: () => _openSiiExportDialog(context),
                ),
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

Future<void> _openSiiExportDialog(BuildContext context) async {
  DateTime? start;
  DateTime? end;
  String book = 'issued'; // 'issued' | 'received'
  bool busy = false;

  await showDialog(
    context: context,
    barrierDismissible: !busy,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> pickStart() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: start ?? DateTime(now.year, now.month, 1),
              firstDate: DateTime(2000),
              lastDate: DateTime(now.year + 1, 12, 31),
            );
            if (picked != null) setState(() => start = picked);
          }

          Future<void> pickEnd() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: end ?? DateTime(now.year, now.month, now.day),
              firstDate: DateTime(2000),
              lastDate: DateTime(now.year + 1, 12, 31),
            );
            if (picked != null) setState(() => end = picked);
          }

          Future<void> doExport() async {
            if (start == null || end == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selecciona inicio y fin')),
              );
              return;
            }
            if (end!.isBefore(start!)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El fin debe ser posterior al inicio'),
                ),
              );
              return;
            }
            setState(() => busy = true);
            try {
              final invoices = context.read<InvoiceRepository>();
              final users = context.read<SelfEmployedUserRepository>();
              final sii = SiiUseCases(invoices, users);
              final uid = FirebaseAuth.instance.currentUser!.uid;
              final jsonStr =
                  (book == 'issued')
                      ? await sii.exportIssuedJson(uid, start: start, end: end)
                      : await sii.exportReceivedJson(
                        uid,
                        start: start,
                        end: end,
                      );

              final name =
                  'SII_${book == 'issued' ? 'expedidas' : 'recibidas'}_${start!.toIso8601String().substring(0, 10)}_${end!.toIso8601String().substring(0, 10)}.json';
              final bytes = Uint8List.fromList(utf8.encode(jsonStr));
              final xfile = XFile.fromData(
                bytes,
                name: name,
                mimeType: 'application/json',
              );
              await SharePlus.instance.share(
                ShareParams(files: [xfile], text: 'Exportación SII ($name)'),
              );
              if (context.mounted) Navigator.of(ctx).pop();
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
            } finally {
              if (ctx.mounted) setState(() => busy = false);
            }
          }

          return AlertDialog(
            title: const Text('Exportar SII'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: book,
                  items: const [
                    DropdownMenuItem(
                      value: 'issued',
                      child: Text('Libro de expedidas (emitidas)'),
                    ),
                    DropdownMenuItem(
                      value: 'received',
                      child: Text('Libro de recibidas'),
                    ),
                  ],
                  onChanged:
                      busy ? null : (v) => setState(() => book = v ?? 'issued'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : pickStart,
                        child: Text(
                          start == null
                              ? 'Inicio'
                              : '${start!.year}-${start!.month.toString().padLeft(2, '0')}-${start!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : pickEnd,
                        child: Text(
                          end == null
                              ? 'Fin'
                              : '${end!.year}-${end!.month.toString().padLeft(2, '0')}-${end!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: busy ? null : doExport,
                icon:
                    busy
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.file_download_outlined),
                label: const Text('Exportar'),
              ),
            ],
          );
        },
      );
    },
  );
}
