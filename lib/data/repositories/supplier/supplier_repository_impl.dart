import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:gestr/domain/entities/supplier_order_item.dart';
import 'package:gestr/domain/entities/supplier_order.dart';
import 'package:gestr/domain/repositories/supplier/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final FirebaseFirestore firestore;
  SupplierRepositoryImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      firestore.collection('users').doc(userId).collection('suppliers');

  @override
  Future<List<Supplier>> getSuppliers(String userId) async {
    final snap = await _col(userId).orderBy('name').get();
    final suppliers = <Supplier>[];
    for (final doc in snap.docs) {
      final m = doc.data();
      if (m['voidedAt'] != null) {
        continue;
      }
      suppliers.add(_mapSupplier(doc.id, m));
    }
    return suppliers;
  }

  @override
  Future<void> createSupplier(String userId, Supplier supplier) async {
    await _col(userId).add({
      'name': supplier.name,
      'email': supplier.email,
      'phone': supplier.phone,
      'taxId': supplier.taxId,
      'fiscalAddress': supplier.fiscalAddress,
      'countryCode': supplier.countryCode,
      'idType': supplier.idType,
      'orderItems': supplier.orderItems.map((i) => i.toMap()).toList(),
      'orders': supplier.orders.map((o) => o.toMap()).toList(),
      'voidedAt': null,
      'voidedBy': null,
      'voidReason': null,
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
      'countryCode': supplier.countryCode,
      'idType': supplier.idType,
      'orderItems': supplier.orderItems.map((i) => i.toMap()).toList(),
      'orders': supplier.orders.map((o) => o.toMap()).toList(),
      'voidedAt': supplier.voidedAt,
      'voidedBy': supplier.voidedBy,
      'voidReason': supplier.voidReason,
    });
  }

  @override
  Future<Supplier> voidSupplier(
    String userId,
    String supplierId, {
    String? voidedBy,
    String? voidReason,
  }) async {
    final docRef = _col(userId).doc(supplierId);
    await docRef.update({
      'voidedAt': FieldValue.serverTimestamp(),
      'voidedBy': voidedBy ?? userId,
      'voidReason': voidReason,
    });
    final updated = await docRef.get();
    if (!updated.exists) {
      throw Exception('Proveedor no encontrado');
    }
    return _mapSupplier(updated.id, updated.data()!);
  }

  @override
  Future<Supplier?> getSupplierById(String userId, String id) async {
    final doc = await _col(userId).doc(id).get();
    if (!doc.exists) return null;
    final m = doc.data()!;
    return _mapSupplier(doc.id, m);
  }

  Supplier _mapSupplier(String id, Map<String, dynamic> data) {
    final ordersRaw = data['orders'] as List<dynamic>?;
    final orderItemsRaw = data['orderItems'] as List<dynamic>?;
    final voidedAtRaw = data['voidedAt'];
    DateTime? voidedAt;
    if (voidedAtRaw is Timestamp) {
      voidedAt = voidedAtRaw.toDate();
    } else if (voidedAtRaw is DateTime) {
      voidedAt = voidedAtRaw;
    } else if (voidedAtRaw is String) {
      voidedAt = DateTime.tryParse(voidedAtRaw);
    }
    return Supplier(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      taxId: data['taxId'] as String?,
      fiscalAddress: data['fiscalAddress'] as String?,
      countryCode: data['countryCode'] as String?,
      idType: data['idType'] as String?,
      orderItems:
          orderItemsRaw
              ?.map(
                (e) => SupplierOrderItem.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          const [],
      orders:
          ordersRaw
              ?.map(
                (o) => SupplierOrder.fromMap(
                  Map<String, dynamic>.from(o as Map<String, dynamic>),
                ),
              )
              .toList() ??
          const [],
      voidedAt: voidedAt,
      voidedBy: data['voidedBy'] as String?,
      voidReason: data['voidReason'] as String?,
    );
  }
}
