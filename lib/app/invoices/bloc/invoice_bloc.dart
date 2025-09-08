import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:gestr/domain/usecases/invoice/invoice_usecases.dart';
import 'package:gestr/domain/entities/income.dart';
import 'package:gestr/domain/usecases/income/income_usecases.dart';

import 'invoice_event.dart';
import 'invoice_state.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final InvoiceUseCases useCases;
   final IncomeUseCases incomeUseCases;
  final String userId;
   InvoiceBloc(
    this.useCases,
    this.incomeUseCases,
    this.userId,
  ) : super(InvoiceInitial()) {
    on<InvoiceEvent>(_onEvent);
  }
  Future<void> _onEvent(InvoiceEvent event, Emitter<InvoiceState> emit) async {
    switch (event.type) {
      case InvoiceEventType.fetch:
        await _handleFetch(emit);
        break;
      case InvoiceEventType.refresh:
        await _handleRefresh(emit);
        break;
      case InvoiceEventType.create:
        await _handleCreate(event.invoice!, emit);
        break;
      case InvoiceEventType.delete:
        await _handleDelete(event.invoiceId!, emit);
        break;
      case InvoiceEventType.getById:
        await _handleGetById(event.invoiceId!, emit);
        break;
          case InvoiceEventType.update:
        await _handleUpdate(event.invoice!, emit);
        break;
      default:
        break;
    }
  }

  Future<void> _handleGetById(
    String invoiceId,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    try {
      final invoice = await useCases.getInvoiceById(userId, invoiceId);
      if (invoice != null) {
        emit(InvoiceLoaded([invoice]));
      } else {
        emit(InvoiceError("Factura no encontrada."));
      }
    } catch (e) {
      emit(InvoiceError("No se pudo cargar la factura."));
    }
  }

  Future<void> _handleDelete(
    String invoiceId,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      await useCases.deleteInvoice(userId, invoiceId);
      final invoices = await useCases.fetchInvoices(userId);
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      emit(InvoiceError("No se pudo eliminar la factura."));
    }
  }

  Future<void> _handleFetch(Emitter<InvoiceState> emit) async {
    emit(InvoiceLoading());
    try {
      final invoices = await useCases.fetchInvoices(userId);
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      emit(InvoiceError("No se pudieron cargar las facturas."));
    }
  }

  Future<void> _handleRefresh(Emitter<InvoiceState> emit) async {
    try {
      final invoices = await useCases.fetchInvoices(userId);
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      emit(InvoiceError("Error al refrescar las facturas."));
    }
  }

  Future<void> _handleCreate(
    Invoice invoice,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      await useCases.createInvoice(userId, invoice);
     if (invoice.status == InvoiceStatus.sent) {
        await incomeUseCases.create(
          userId,
          Income(
            title: invoice.title,
            date: invoice.date,
            amount: invoice.netAmount,
            source: invoice.receiver,
          ),
        );
      }
      
      final invoices = await useCases.fetchInvoices(userId);
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      emit(InvoiceError("No se pudo crear la factura."));
    }
  }


  Future<void> _handleUpdate(
    Invoice invoice,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      await useCases.updateInvoice(userId, invoice);
      if (invoice.status == InvoiceStatus.sent) {
        await incomeUseCases.create(
          userId,
          Income(
            title: invoice.title,
            date: invoice.date,
            amount: invoice.netAmount,
            source: invoice.receiver,
          ),
        );
      }
      final invoices = await useCases.fetchInvoices(userId);
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      emit(InvoiceError("No se pudo actualizar la factura."));
    }
  }}

