import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestr/app/tax/bloc/summary/summary_event.dart';
import 'package:gestr/app/tax/bloc/summary/summary_state.dart';
import 'package:gestr/domain/usecases/tax/tax_summary_usecases.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final TaxSummaryUseCases useCases;
  final String userId;
  SummaryBloc(this.useCases, this.userId) : super(SummaryInitial()) {
    on<SummaryEvent>((event, emit) async {
      if (state is! SummaryLoaded) emit(SummaryLoading());
      final r = event.range ?? _defaultRange();
      try {
        final summary = await useCases.fetchSummary(
          userId,
          start: r.start,
          end: r.end,
        );
        final diff = r.end.difference(r.start);
        final prevEnd = r.start.subtract(const Duration(milliseconds: 1));
        final prevStart = prevEnd.subtract(diff);
        final previous = await useCases.fetchSummary(
          userId,
          start: prevStart,
          end: prevEnd,
        );
        emit(SummaryLoaded(summary: summary, previous: previous, range: r));
      } catch (e) {
        emit(SummaryError(e.toString()));
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
