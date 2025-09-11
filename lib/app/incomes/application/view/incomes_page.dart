import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/incomes/bloc/income_bloc.dart';
import 'package:gestr/app/incomes/bloc/income_event.dart';
import 'package:gestr/app/incomes/bloc/income_state.dart';
import 'package:gestr/domain/entities/income.dart';
import '../../widgets/income_card.dart';

class IncomesPage extends StatefulWidget {
  const IncomesPage({super.key});
  @override
  State<IncomesPage> createState() => _IncomesPageState();
}

class _IncomesPageState extends State<IncomesPage> {
  @override
  void initState() {
    super.initState();
    context.read<IncomeBloc>().add(const IncomeEvent.fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42.0, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ingresos',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 28),
                tooltip: 'Crear ingreso',
                onPressed: () => Navigator.pushNamed(context, '/create-income'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<IncomeBloc, IncomeState>(
              builder: (context, state) {
                if (state is IncomeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is IncomeError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                if (state is! IncomeLoaded) {
                  return const SizedBox.shrink();
                }
                final incomes = state.incomes;
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final total = incomes.fold<double>(
                  0,
                  (sum, inc) => sum + inc.amount,
                );
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color:
                        isDark
                            ? Colors.deepPurple.withAlpha(25)
                            : Colors.teal.withAlpha(25),
                  ),
                  child:
                      incomes.isEmpty
                          ? _buildEmptyMessage(isDark)
                          : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    Text(
                                      '${total.toStringAsFixed(2)} €',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: incomes.length,
                                  itemBuilder: (context, i) {
                                    final inc = incomes[i];
                                    return IncomeCard(
                                      income: inc,
                                      onDelete: () => _confirmDelete(inc),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(bool isDark) {
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

  void _confirmDelete(Income inc) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text('Eliminar ingreso'),
                content: Text('¿Eliminar "${inc.title}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
        ) ??
        false;
    if (!mounted) {
      return;
    }
    if (ok && inc.id != null) {
      context.read<IncomeBloc>().add(IncomeEvent.delete(inc.id!));
    }
  }
}
