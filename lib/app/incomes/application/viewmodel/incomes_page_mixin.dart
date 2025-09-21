import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/incomes/application/view/incomes_page.dart';
import 'package:gestr/app/incomes/bloc/income_bloc.dart';
import 'package:gestr/app/incomes/bloc/income_event.dart';
import 'package:gestr/app/widgets/void_confirmation_dialog.dart';
import 'package:gestr/domain/entities/income.dart';

mixin IncomesPageMixin on State<IncomesPage> {
  Widget buildEmptyMessage(bool isDark) {
    final color = isDark ? Colors.deepPurpleAccent : Colors.teal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              'No hay ingresos todavía.',
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tu primer ingreso para comenzar a gestionarlos.',
              style: TextStyle(fontSize: 14, color: color.withAlpha(180)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/create-income'),
              icon: const Icon(Icons.add),
              label: const Text('Crear ingreso'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmDelete(Income inc) async {
    final reason = await showVoidConfirmationDialog(
      context: context,
      title: 'Anular ingreso',
      message: '¿Quieres anular "${inc.title}"?',
    );
    if (!mounted || inc.id == null || reason == null) return;
    final trimmedReason = reason.trim();
    context.read<IncomeBloc>().add(
      IncomeEvent.delete(
        inc.id!,
        voidReason: trimmedReason.isEmpty ? null : trimmedReason,
      ),
    );
  }
}
