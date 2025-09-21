import 'package:gestr/domain/entities/supplier.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> getSuppliers(String userId);
  Future<void> createSupplier(String userId, Supplier supplier);
  Future<void> updateSupplier(String userId, Supplier supplier);
  Future<Supplier> voidSupplier(
    String userId,
    String supplierId, {
    String? voidedBy,
    String? voidReason,
  });
  Future<Supplier?> getSupplierById(String userId, String id);
}
