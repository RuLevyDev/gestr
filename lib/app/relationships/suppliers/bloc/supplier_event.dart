import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/supplier.dart';

enum SupplierEventType { fetch, refresh, create, delete, getById, update }

class SupplierEvent extends Equatable {
  final SupplierEventType type;
  final Supplier? supplier;
  final String? id;

  const SupplierEvent._(this.type, {this.supplier, this.id});
  const SupplierEvent.fetch() : this._(SupplierEventType.fetch);
  const SupplierEvent.refresh() : this._(SupplierEventType.refresh);
  const SupplierEvent.create(Supplier supplier)
    : this._(SupplierEventType.create, supplier: supplier);
  const SupplierEvent.delete(String id)
    : this._(SupplierEventType.delete, id: id);
  const SupplierEvent.getById(String id)
    : this._(SupplierEventType.getById, id: id);
  const SupplierEvent.update(Supplier supplier)
    : this._(SupplierEventType.update, supplier: supplier);

  @override
  List<Object?> get props => [type, supplier, id];
}
