import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestr/app/tax/bloc/top_clients/top_clients_event.dart';
import 'package:gestr/app/tax/bloc/top_clients/top_clients_state.dart';
import 'package:gestr/domain/usecases/tax/tax_summary_usecases.dart';

class TopClientsBloc extends Bloc<TopClientsEvent, TopClientsState> {
  final TaxSummaryUseCases useCases;
  final String userId;
  TopClientsBloc(this.useCases, this.userId) : super(TopClientsInitial()) {
    on<TopClientsEvent>((event, emit) async {
      if (state is! TopClientsLoaded) emit(TopClientsLoading());
      final range = event.range ?? _defaultRange();
      try {
        final list = await useCases.topClients(
          userId,
          start: range.start,
          end: range.end,
          limit: 5,
        );
        emit(TopClientsLoaded(list));
      } catch (e) {
        emit(TopClientsError(e.toString()));
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
