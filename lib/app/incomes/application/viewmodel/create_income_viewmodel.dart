import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/incomes/bloc/income_bloc.dart';
import 'package:gestr/app/incomes/bloc/income_event.dart';
import 'package:gestr/domain/entities/income.dart';

mixin CreateIncomeViewModelMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final sourceCtrl = TextEditingController();
  DateTime date = DateTime.now();

  @override
  void dispose() {
    titleCtrl.dispose();
    amountCtrl.dispose();
    sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: date,
    );
    if (picked != null) {
      setState(() => date = picked);
    }
  }

  void save() {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    final amount = double.parse(amountCtrl.text.trim());
    final inc = Income(
      title: titleCtrl.text.trim(),
      date: date,
      amount: amount,
      source: sourceCtrl.text.trim().isEmpty ? null : sourceCtrl.text.trim(),
    );
    context.read<IncomeBloc>().add(IncomeEvent.create(inc));
    Navigator.pop(context);
  }
}
