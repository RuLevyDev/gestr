import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/domain/entities/income.dart';
import 'package:gestr/domain/usecases/income/income_usecases.dart';

import 'income_event.dart';
import 'income_state.dart';

class IncomeBloc extends Bloc<IncomeEvent, IncomeState> {
  final IncomeUseCases useCases;
  final String userId;
  IncomeBloc(this.useCases, this.userId) : super(IncomeInitial()) {
    on<IncomeEvent>(_onEvent);
  }

  Future<void> _onEvent(IncomeEvent event, Emitter<IncomeState> emit) async {
    switch (event.type) {
      case IncomeEventType.fetch:
        await _fetch(emit);
        break;
      case IncomeEventType.refresh:
        await _refresh(emit);
        break;
      case IncomeEventType.create:
        await _create(event.income!, emit);
        break;
      case IncomeEventType.delete:
        await _delete(event.id!, emit, voidReason: event.voidReason);
      case IncomeEventType.getById:
        await _getById(event.id!, emit);
        break;
    }
  }

  Future<void> _fetch(Emitter<IncomeState> emit) async {
    emit(IncomeLoading());
    try {
      final list = await useCases.fetch(userId);
      emit(IncomeLoaded(list));
    } catch (_) {
      emit(const IncomeError('No se pudieron cargar los ingresos.'));
    }
  }

  Future<void> _refresh(Emitter<IncomeState> emit) async {
    try {
      final list = await useCases.fetch(userId);
      emit(IncomeLoaded(list));
    } catch (_) {
      emit(const IncomeError('Error al refrescar los ingresos.'));
    }
  }

  Future<void> _create(Income income, Emitter<IncomeState> emit) async {
    try {
      await useCases.create(userId, income);
      final list = await useCases.fetch(userId);
      emit(IncomeLoaded(list));
    } catch (_) {
      emit(const IncomeError('No se pudo crear el ingreso.'));
    }
  }

  Future<void> _delete(
    String id,
    Emitter<IncomeState> emit, {
    String? voidReason,
  }) async {
    try {
      await useCases.voidIncome(
        userId,
        id,
        voidedBy: userId,
        voidReason: voidReason,
      );
      final list = await useCases.fetch(userId);
      emit(IncomeLoaded(list));
    } catch (_) {
      emit(const IncomeError('No se pudo anular el ingreso.'));
    }
  }

  Future<void> _getById(String id, Emitter<IncomeState> emit) async {
    emit(IncomeLoading());
    try {
      final item = await useCases.getById(userId, id);
      if (item == null) {
        emit(const IncomeError('Ingreso no encontrado.'));
      } else {
        emit(IncomeLoaded([item]));
      }
    } catch (_) {
      emit(const IncomeError('No se pudo cargar el ingreso.'));
    }
  }
}
