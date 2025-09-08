import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/incomes/bloc/income_bloc.dart';
import 'package:gestr/app/incomes/bloc/income_event.dart';
import 'package:gestr/app/incomes/bloc/income_state.dart';
import 'package:gestr/domain/entities/income.dart';

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
              Text('Ingresos', style: Theme.of(context).textTheme.headlineMedium),
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
                if (incomes.isEmpty) {
                  return Center(
                    child: Text('No hay ingresos todavía.'),
                  );
                }
                return ListView.separated(
                  itemCount: incomes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final inc = incomes[i];
                    return ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: Text(inc.title),
                      subtitle: Text(_fmtDate(inc.date) + (inc.source != null ? ' · ${inc.source}' : '')),
                      trailing: Text('${inc.amount.toStringAsFixed(2)} EUR'),
                      onLongPress: () => _confirmDelete(context, inc),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _confirmDelete(BuildContext context, Income inc) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Eliminar ingreso'),
            content: Text('¿Eliminar "${inc.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
            ],
          ),
        ) ??
        false;
    if (ok && inc.id != null) {
      context.read<IncomeBloc>().add(IncomeEvent.delete(inc.id!));
    }
  }
}

