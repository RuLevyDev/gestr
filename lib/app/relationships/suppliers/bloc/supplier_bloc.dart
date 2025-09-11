import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:gestr/domain/usecases/supplier/supplier_usecases.dart';

import 'supplier_event.dart';
import 'supplier_state.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final SupplierUseCases useCases;
  final String userId;
  SupplierBloc(this.useCases, this.userId) : super(SupplierInitial()) {
    on<SupplierEvent>(_onEvent);
  }

  Future<void> _onEvent(
    SupplierEvent event,
    Emitter<SupplierState> emit,
  ) async {
    switch (event.type) {
      case SupplierEventType.fetch:
        await _fetch(emit);
        break;
      case SupplierEventType.refresh:
        await _refresh(emit);
        break;
      case SupplierEventType.create:
        await _create(event.supplier!, emit);
        break;
      case SupplierEventType.delete:
        await _delete(event.id!, emit);
        break;
      case SupplierEventType.getById:
        await _getById(event.id!, emit);
        break;
      case SupplierEventType.update:
        await _update(event.supplier!, emit);
        break;
    }
  }

  Future<void> _fetch(Emitter<SupplierState> emit) async {
    emit(SupplierLoading());
    try {
      final list = await useCases.fetch(userId);
      emit(SupplierLoaded(list));
    } catch (_) {
      emit(const SupplierError('No se pudieron cargar los proveedores.'));
    }
  }

  Future<void> _refresh(Emitter<SupplierState> emit) async {
    try {
      final list = await useCases.fetch(userId);
      emit(SupplierLoaded(list));
    } catch (_) {
      emit(const SupplierError('Error al refrescar los proveedores.'));
    }
  }

  Future<void> _create(Supplier supplier, Emitter<SupplierState> emit) async {
    try {
      await useCases.create(userId, supplier);
      final list = await useCases.fetch(userId);
      emit(SupplierLoaded(list));
    } catch (_) {
      emit(const SupplierError('No se pudo crear el proveedor.'));
    }
  }

  Future<void> _delete(String id, Emitter<SupplierState> emit) async {
    try {
      await useCases.delete(userId, id);
      final list = await useCases.fetch(userId);
      emit(SupplierLoaded(list));
    } catch (_) {
      emit(const SupplierError('No se pudo eliminar el proveedor.'));
    }
  }

  Future<void> _update(Supplier supplier, Emitter<SupplierState> emit) async {
    try {
      await useCases.update(userId, supplier);
      final list = await useCases.fetch(userId);
      emit(SupplierLoaded(list));
    } catch (_) {
      emit(const SupplierError('No se pudo actualizar el proveedor.'));
    }
  }

  Future<void> _getById(String id, Emitter<SupplierState> emit) async {
    emit(SupplierLoading());
    try {
      final item = await useCases.getById(userId, id);
      if (item == null) {
        emit(const SupplierError('Proveedor no encontrado.'));
      } else {
        emit(SupplierLoaded([item]));
      }
    } catch (_) {
      emit(const SupplierError('No se pudo cargar el proveedor.'));
    }
  }
}
