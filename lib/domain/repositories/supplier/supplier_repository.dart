import 'package:gestr/domain/entities/supplier.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> getSuppliers(String userId);
  Future<void> createSupplier(String userId, Supplier supplier);
  Future<void> updateSupplier(String userId, Supplier supplier);
  Future<void> deleteSupplier(String userId, String supplierId);
  Future<Supplier?> getSupplierById(String userId, String id);
}
