import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestr/app/tax/bloc/expenses_by_category/expenses_by_category_event.dart';
import 'package:gestr/app/tax/bloc/expenses_by_category/expenses_by_category_state.dart';
import 'package:gestr/domain/usecases/tax/tax_summary_usecases.dart';

class ExpensesByCategoryBloc
    extends Bloc<ExpensesByCategoryEvent, ExpensesByCategoryState> {
  final TaxSummaryUseCases useCases;
  final String userId;
  ExpensesByCategoryBloc(this.useCases, this.userId)
    : super(ExpensesByCategoryInitial()) {
    on<ExpensesByCategoryEvent>((event, emit) async {
      if (state is! ExpensesByCategoryLoaded) emit(ExpensesByCategoryLoading());
      final range = event.range ?? _defaultRange();
      try {
        final list = await useCases.expensesByCategory(
          userId,
          start: range.start,
          end: range.end,
        );
        emit(ExpensesByCategoryLoaded(list));
      } catch (e) {
        emit(ExpensesByCategoryError(e.toString()));
      }
    });
  }

  DateTimeRange _defaultRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
    );
  }
}
