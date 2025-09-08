import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestr/app/tax/bloc/vat/vat_event.dart';
import 'package:gestr/app/tax/bloc/vat/vat_state.dart';
import 'package:gestr/domain/usecases/tax/tax_summary_usecases.dart';

class VatBloc extends Bloc<VatEvent, VatState> {
  final TaxSummaryUseCases useCases;
  final String userId;
  VatBloc(this.useCases, this.userId) : super(VatInitial()) {
    on<VatEvent>((event, emit) async {
      if (state is! VatLoaded) emit(VatLoading());
      final range = event.range ?? _defaultRange();
      try {
        final vat = await useCases.vatBreakdown(
          userId,
          start: range.start,
          end: range.end,
        );
        emit(VatLoaded(vat));
      } catch (e) {
        emit(VatError(e.toString()));
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
