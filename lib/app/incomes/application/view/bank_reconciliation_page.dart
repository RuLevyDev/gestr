import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/incomes/bloc/bank_transaction_bloc.dart';
import 'package:gestr/app/incomes/bloc/bank_transaction_event.dart';
import 'package:gestr/app/incomes/bloc/bank_transaction_state.dart';
import 'package:gestr/app/incomes/bloc/income_bloc.dart';
import 'package:gestr/app/incomes/bloc/income_event.dart';
import 'package:gestr/app/incomes/bloc/income_state.dart';
import 'package:gestr/domain/entities/bank_transaction.dart';
import 'package:gestr/domain/entities/income.dart';

class BankReconciliationPage extends StatefulWidget {
  const BankReconciliationPage({super.key});

  @override
  State<BankReconciliationPage> createState() => _BankReconciliationPageState();
}

class _BankReconciliationPageState extends State<BankReconciliationPage> {
  @override
  void initState() {
    super.initState();
    context.read<BankTransactionBloc>().add(const BankTransactionEvent.fetch());
    context.read<IncomeBloc>().add(const IncomeEvent.fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conciliación bancaria')),
      body: BlocBuilder<BankTransactionBloc, BankTransactionState>(
        builder: (context, state) {
          if (state is BankTransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BankTransactionError) {
            return Center(child: Text(state.message));
          }
          if (state is! BankTransactionLoaded) {
            return const SizedBox.shrink();
          }
          final txs = state.transactions;
          if (txs.isEmpty) {
            return const Center(child: Text('No hay transacciones'));
          }
          return ListView.builder(
            itemCount: txs.length,
            itemBuilder: (context, i) {
              final tx = txs[i];
              return ListTile(
                title: Text(tx.description),
                subtitle: Text('${tx.amount.toStringAsFixed(2)} €'),
                trailing: Text(
                  '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}',
                ),
                onTap: () => _selectIncome(tx),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _selectIncome(BankTransaction tx) async {
    final incomeState = context.read<IncomeBloc>().state;
    if (incomeState is! IncomeLoaded) return;
    final selected = await showDialog<Income>(
      context: context,
      builder:
          (ctx) => SimpleDialog(
            title: const Text('Selecciona un ingreso'),
            children:
                incomeState.incomes
                    .map(
                      (inc) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, inc),
                        child: Text(inc.title),
                      ),
                    )
                    .toList(),
          ),
    );
    if (!mounted) return;
    if (selected != null && tx.id != null && selected.id != null) {
      context.read<BankTransactionBloc>().add(
        BankTransactionEvent.link(tx.id!, selected.id!),
      );
    }
  }
}
