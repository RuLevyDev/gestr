import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';

import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/domain/usecases/fixed_payments_usecases.dart/fixed_payment_usecases.dart';

class FixedPaymentBloc extends Bloc<FixedPaymentEvent, FixedPaymentState> {
  final FixedPaymentUseCases useCases;
  final String userId;

  FixedPaymentBloc(this.useCases, this.userId) : super(FixedPaymentInitial()) {
    on<FixedPaymentEvent>(_onEvent);
  }

  Future<void> _onEvent(
    FixedPaymentEvent event,
    Emitter<FixedPaymentState> emit,
  ) async {
    switch (event.type) {
      case FixedPaymentEventType.fetch:
        await _handleFetch(emit);
        break;
      case FixedPaymentEventType.refresh:
        await _handleRefresh(emit);
        break;
      case FixedPaymentEventType.create:
        await _handleCreate(event.fixedPayment!, emit);
        break;
      case FixedPaymentEventType.update:
        await _handleUpdate(event.fixedPayment!, emit);
        break;
      case FixedPaymentEventType.delete:
        await _handleDelete(event.paymentId!, emit);
        break;
      case FixedPaymentEventType.getById:
        await _handleGetById(event.paymentId!, emit);
        break;
    }
  }

  Future<void> _handleGetById(
    String paymentId,
    Emitter<FixedPaymentState> emit,
  ) async {
    emit(FixedPaymentLoading());
    try {
      final payment = await useCases.getFixedPaymentById(userId, paymentId);
      if (payment != null) {
        emit(FixedPaymentLoaded([payment]));
      } else {
        emit(FixedPaymentError("Pago fijo no encontrado."));
      }
    } catch (_) {
      emit(FixedPaymentError("No se pudo cargar el pago fijo."));
    }
  }

  Future<void> _handleDelete(
    String paymentId,
    Emitter<FixedPaymentState> emit,
  ) async {
    try {
      await useCases.deleteFixedPayment(userId, paymentId);
      final payments = await useCases.fetchFixedPayments(userId);
      emit(FixedPaymentLoaded(payments));
    } catch (_) {
      emit(FixedPaymentError("No se pudo eliminar el pago fijo."));
    }
  }

  Future<void> _handleFetch(Emitter<FixedPaymentState> emit) async {
    emit(FixedPaymentLoading());
    try {
      final payments = await useCases.fetchFixedPayments(userId);
      emit(FixedPaymentLoaded(payments));
    } catch (_) {
      emit(FixedPaymentError("No se pudieron cargar los pagos fijos."));
    }
  }

  Future<void> _handleRefresh(Emitter<FixedPaymentState> emit) async {
    try {
      final payments = await useCases.fetchFixedPayments(userId);
      emit(FixedPaymentLoaded(payments));
    } catch (_) {
      emit(FixedPaymentError("Error al refrescar los pagos fijos."));
    }
  }

  Future<void> _handleCreate(
    FixedPayment payment,
    Emitter<FixedPaymentState> emit,
  ) async {
    try {
      await useCases.createFixedPayment(userId, payment);
      final payments = await useCases.fetchFixedPayments(userId);
      emit(FixedPaymentLoaded(payments));
    } catch (e, stackTrace) {
      debugPrint('Error al crear el pago fijo: $e');
      debugPrintStack(stackTrace: stackTrace);
      emit(FixedPaymentError("No se pudo crear el pago fijo."));
    }
  }

  Future<void> _handleUpdate(
    FixedPayment payment,
    Emitter<FixedPaymentState> emit,
  ) async {
    try {
      await useCases.updateFixedPayment(userId, payment);
      final payments = await useCases.fetchFixedPayments(userId);
      emit(FixedPaymentLoaded(payments));
    } catch (e, stackTrace) {
      debugPrint('Error al actualizar el pago fijo: $e');
      debugPrintStack(stackTrace: stackTrace);
      emit(FixedPaymentError("No se pudo actualizar el pago fijo."));
    }
  }
}
