import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestr/app/tax/bloc/pre303/pre303_event.dart';
import 'package:gestr/app/tax/bloc/pre303/pre303_state.dart';
import 'package:gestr/domain/usecases/tax/tax_summary_usecases.dart';

class Pre303Bloc extends Bloc<Pre303Event, Pre303State> {
  final TaxSummaryUseCases useCases;
  final String userId;
  Pre303Bloc(this.useCases, this.userId) : super(Pre303Initial()) {
    on<Pre303Event>((event, emit) async {
      if (state is! Pre303Loaded) emit(Pre303Loading());
      final range = event.range ?? _defaultRange();
      try {
        final p = await useCases.pre303(
          userId,
          start: range.start,
          end: range.end,
        );
        emit(Pre303Loaded(p));
      } catch (e) {
        emit(Pre303Error(e.toString()));
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
