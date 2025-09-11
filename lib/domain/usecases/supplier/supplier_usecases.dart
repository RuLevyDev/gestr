import 'package:gestr/domain/entities/supplier.dart';
import 'package:gestr/domain/repositories/supplier/supplier_repository.dart';

class SupplierUseCases {
  final SupplierRepository _repo;
  SupplierUseCases(this._repo);

  Future<List<Supplier>> fetch(String userId) => _repo.getSuppliers(userId);
  Future<void> create(String userId, Supplier supplier) =>
      _repo.createSupplier(userId, supplier);
  Future<void> update(String userId, Supplier supplier) =>
      _repo.updateSupplier(userId, supplier);
  Future<void> delete(String userId, String id) =>
      _repo.deleteSupplier(userId, id);
  Future<Supplier?> getById(String userId, String id) =>
      _repo.getSupplierById(userId, id);
}
