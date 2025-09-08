import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestr/app/tax/bloc/chart/chart_event.dart';
import 'package:gestr/app/tax/bloc/chart/chart_state.dart';
import 'package:gestr/domain/usecases/tax/tax_summary_usecases.dart';

class ChartBloc extends Bloc<ChartEvent, ChartState> {
  final TaxSummaryUseCases useCases;
  final String userId;
  ChartBloc(this.useCases, this.userId) : super(ChartInitial()) {
    on<ChartEvent>((event, emit) async {
      if (state is! ChartLoaded) emit(ChartLoading());
      final r = event.range ?? _defaultRange();
      try {
        final labels = <String>[];
        final income = <double>[];
        final expenses = <double>[];

        final isSingleMonth = r.start.year == r.end.year && r.start.month == r.end.month;
        if (isSingleMonth) {
          final days = _daysBetween(r.start, r.end);
          final futures = days
              .map((d) => useCases
                      .fetchSummary(userId, start: DateTime(d.year, d.month, d.day), end: DateTime(d.year, d.month, d.day, 23, 59, 59, 999))
                      .then((s) => MapEntry(d, s)))
              .toList();
          final results = await Future.wait(futures);
          for (final e in results) {
            labels.add(_labelForDay(e.key));
            income.add(e.value.totalIncome);
            expenses.add(e.value.totalExpenses);
          }
        } else {
          final months = _monthsBetween(r.start, r.end);
          final futures = months
              .map((m) => useCases
                      .fetchSummary(userId, start: DateTime(m.year, m.month, 1), end: DateTime(m.year, m.month + 1, 0, 23, 59, 59, 999))
                      .then((s) => MapEntry(m, s)))
              .toList();
          final results = await Future.wait(futures);
          for (final e in results) {
            labels.add(_labelForMonth(e.key));
            income.add(e.value.totalIncome);
            expenses.add(e.value.totalExpenses);
          }
        }

        // YoY (mismo periodo año anterior)
        final yr = DateTimeRange(
          start: DateTime(r.start.year - 1, r.start.month, r.start.day),
          end: DateTime(r.end.year - 1, r.end.month, r.end.day),
        );
        final yoyIncome = <double>[];
        final yoyExpenses = <double>[];
        if (isSingleMonth) {
          final days = _daysBetween(yr.start, yr.end);
          final futures = days
              .map((d) => useCases
                      .fetchSummary(userId, start: DateTime(d.year, d.month, d.day), end: DateTime(d.year, d.month, d.day, 23, 59, 59, 999))
                      .then((s) => s))
              .toList();
          final results = await Future.wait(futures);
          for (final s in results) {
            yoyIncome.add(s.totalIncome);
            yoyExpenses.add(s.totalExpenses);
          }
        } else {
          final months = _monthsBetween(yr.start, yr.end);
          final futures = months
              .map((m) => useCases
                      .fetchSummary(userId, start: DateTime(m.year, m.month, 1), end: DateTime(m.year, m.month + 1, 0, 23, 59, 59, 999))
                      .then((s) => s))
              .toList();
          final results = await Future.wait(futures);
          for (final s in results) {
            yoyIncome.add(s.totalIncome);
            yoyExpenses.add(s.totalExpenses);
          }
        }

        emit(ChartLoaded(
          range: r,
          labels: labels,
          income: income,
          expenses: expenses,
          yoyIncome: yoyIncome,
          yoyExpenses: yoyExpenses,
        ));
      } catch (e) {
        emit(ChartError(e.toString()));
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

  List<DateTime> _monthsBetween(DateTime start, DateTime end) {
    final first = DateTime(start.year, start.month);
    final last = DateTime(end.year, end.month);
    final months = <DateTime>[];
    var current = first;
    while (current.isBefore(last) || (current.year == last.year && current.month == last.month)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1);
    }
    return months;
  }

  List<DateTime> _daysBetween(DateTime start, DateTime end) {
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    final days = <DateTime>[];
    var current = first;
    while (!current.isAfter(last)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  String _labelForMonth(DateTime d) {
    const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${months[d.month - 1]} ${d.year % 100}'.padRight(6);
  }

  String _labelForDay(DateTime d) {
    const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}';
  }
}
