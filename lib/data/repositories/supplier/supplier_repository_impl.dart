import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:gestr/domain/repositories/supplier/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final FirebaseFirestore firestore;
  SupplierRepositoryImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      firestore.collection('users').doc(userId).collection('suppliers');

  @override
  Future<List<Supplier>> getSuppliers(String userId) async {
    final snap = await _col(userId).orderBy('name').get();
    return snap.docs.map((d) {
      final m = d.data();
      return Supplier(
        id: d.id,
        name: m['name'] ?? '',
        email: m['email'],
        phone: m['phone'],
        taxId: m['taxId'],
        fiscalAddress: m['fiscalAddress'],
      );
    }).toList();
  }

  @override
  Future<void> createSupplier(String userId, Supplier supplier) async {
    await _col(userId).add({
      'name': supplier.name,
      'email': supplier.email,
      'phone': supplier.phone,
      'taxId': supplier.taxId,
      'fiscalAddress': supplier.fiscalAddress,
    });
  }

  @override
  Future<void> updateSupplier(String userId, Supplier supplier) async {
    if (supplier.id == null) return;
    await _col(userId).doc(supplier.id).update({
      'name': supplier.name,
      'email': supplier.email,
      'phone': supplier.phone,
      'taxId': supplier.taxId,
      'fiscalAddress': supplier.fiscalAddress,
    });
  }

  @override
  Future<void> deleteSupplier(String userId, String supplierId) async {
    await _col(userId).doc(supplierId).delete();
  }

  @override
  Future<Supplier?> getSupplierById(String userId, String id) async {
    final doc = await _col(userId).doc(id).get();
    if (!doc.exists) return null;
    final m = doc.data()!;
    return Supplier(
      id: doc.id,
      name: m['name'] ?? '',
      email: m['email'],
      phone: m['phone'],
      taxId: m['taxId'],
      fiscalAddress: m['fiscalAddress'],
    );
  }
}
