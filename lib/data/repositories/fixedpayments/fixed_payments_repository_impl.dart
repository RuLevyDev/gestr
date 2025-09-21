import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/domain/repositories/fixedpayments/fixed_payments_repository.dart';

class FixedPaymentRepositoryImpl implements FixedPaymentRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  FixedPaymentRepositoryImpl(this.firestore)
    : storage = FirebaseStorage.instance;

  @override
  Future<List<FixedPayment>> getFixedPayments(String userId) async {
    try {
      final snapshot =
          await firestore
              .collection('users')
              .doc(userId)
              .collection('fixedPayments')
              .orderBy('startDate', descending: true)
              .get();

      final payments = <FixedPayment>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['voidedAt'] != null) {
          continue;
        }
        payments.add(_mapFixedPayment(doc.id, data));
      }
      return payments;
    } catch (e) {
      throw Exception("Error al obtener los pagos fijos: $e");
    }
  }

  @override
  Future<void> createFixedPayment(String userId, FixedPayment payment) async {
    try {
      String? imageUrl;

      if (payment.image != null) {
        imageUrl = await _uploadImage(payment.image!, 'fixedPayments');
      }

      await firestore
          .collection('users')
          .doc(userId)
          .collection('fixedPayments')
          .add({
            'title': payment.title,
            'amount': payment.amount,
            'startDate': payment.startDate,
            'frequency': payment.frequency.name, // Ej: "monthly"
            'description': payment.description,
            'supplier': payment.supplier,
            'vatRate': payment.vatRate,
            'amountIsGross': payment.amountIsGross,
            'deductible': payment.deductible,
            'category': payment.category.name,
            'imageUrl': imageUrl,
            'voidedAt': null,
            'voidedBy': null,
            'voidReason': null,
          });
    } catch (e) {
      throw Exception("Error al crear el pago fijo: $e");
    }
  }

  @override
  Future<void> updateFixedPayment(String userId, FixedPayment payment) async {
    try {
      final docRef = firestore
          .collection('users')
          .doc(userId)
          .collection('fixedPayments')
          .doc(payment.id);

      final doc = await docRef.get();
      String? imageUrl = payment.imageUrl;

      if (payment.image != null) {
        if (doc.exists && doc.data()!['imageUrl'] != null) {
          final oldImageUrl = doc.data()!['imageUrl'] as String;
          final oldRef = storage.refFromURL(oldImageUrl);
          await oldRef.delete();
        }

        imageUrl = await _uploadImage(payment.image!, 'fixedPayments');
      }

      await docRef.update({
        'title': payment.title,
        'amount': payment.amount,
        'startDate': payment.startDate,
        'frequency': payment.frequency.name,
        'description': payment.description,
        'supplier': payment.supplier,
        'vatRate': payment.vatRate,
        'amountIsGross': payment.amountIsGross,
        'deductible': payment.deductible,
        'category': payment.category.name,
        'imageUrl': imageUrl,
        'voidedAt': payment.voidedAt,
        'voidedBy': payment.voidedBy,
        'voidReason': payment.voidReason,
      });
    } catch (e) {
      throw Exception("Error al actualizar el pago fijo: $e");
    }
  }

  @override
  Future<FixedPayment> voidFixedPayment(
    String userId,
    String paymentId, {
    String? voidedBy,
    String? voidReason,
  }) async {
    try {
      final docRef = firestore
          .collection('users')
          .doc(userId)
          .collection('fixedPayments')
          .doc(paymentId);

      await docRef.update({
        'voidedAt': FieldValue.serverTimestamp(),
        'voidedBy': voidedBy ?? userId,
        'voidReason': voidReason,
      });

      final updated = await docRef.get();
      if (!updated.exists) {
        throw Exception('Pago fijo no encontrado');
      }

      return _mapFixedPayment(updated.id, updated.data()!);
    } catch (e) {
      throw Exception("Error al anular el pago fijo: $e");
    }
  }

  @override
  Future<FixedPayment?> getFixedPaymentById(String userId, String id) async {
    try {
      final doc =
          await firestore
              .collection('users')
              .doc(userId)
              .collection('fixedPayments')
              .doc(id)
              .get();

      if (!doc.exists) return null;

      final data = doc.data()!;

      return _mapFixedPayment(doc.id, data);
    } catch (e) {
      throw Exception("Error al obtener el pago fijo por ID: $e");
    }
  }

  FixedPayment _mapFixedPayment(String id, Map<String, dynamic> data) {
    final voidedAtRaw = data['voidedAt'];
    DateTime? voidedAt;
    if (voidedAtRaw is Timestamp) {
      voidedAt = voidedAtRaw.toDate();
    } else if (voidedAtRaw is DateTime) {
      voidedAt = voidedAtRaw;
    } else if (voidedAtRaw is String) {
      voidedAt = DateTime.tryParse(voidedAtRaw);
    }
    return FixedPayment(
      id: id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      frequency: _parseStatus(data['frequency']),
      description: data['description'] as String?,
      supplier: data['supplier'] as String?,
      vatRate: ((data['vatRate'] ?? 0.0) as num).toDouble(),
      amountIsGross: (data['amountIsGross'] ?? true) as bool,
      deductible: (data['deductible'] ?? true) as bool,
      category: _parseCategory(data['category']),
      imageUrl: data['imageUrl'] as String?,
      voidedAt: voidedAt,
      voidedBy: data['voidedBy'] as String?,
      voidReason: data['voidReason'] as String?,
    );
  }

  Future<String> _uploadImage(File file, String folder) async {
    final ext = _resolveExtension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final ref = storage.ref().child('$folder/$fileName');
    final metadata = SettableMetadata(
      contentType: _contentTypeForExtension(ext),
    );
    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  String _resolveExtension(String path) {
    final normalised = path.replaceAll('\\', '/');
    final name = normalised.split('/').last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < name.length - 1) {
      return name.substring(dotIndex).toLowerCase();
    }
    return '.bin';
  }

  String _contentTypeForExtension(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.jp2':
      case '.jpf':
      case '.jpx':
        return 'image/jp2';
      case '.tif':
      case '.tiff':
        return 'image/tiff';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  FixedPaymentFrequency _parseStatus(String? status) {
    const mapping = {
      'weekly': FixedPaymentFrequency.weekly,
      'monthly': FixedPaymentFrequency.monthly,
      'quarterly': FixedPaymentFrequency.quarterly,
      'fourmonthly': FixedPaymentFrequency.fourMonthly,
      'semiyearly': FixedPaymentFrequency.semiYearly,
      'yearly': FixedPaymentFrequency.yearly,
      'custom': FixedPaymentFrequency.custom,
    };

    return mapping[status?.toLowerCase()] ?? FixedPaymentFrequency.monthly;
  }

  FixedPaymentCategory _parseCategory(String? cat) {
    switch ((cat ?? '').toLowerCase()) {
      case 'utilities':
        return FixedPaymentCategory.utilities;
      case 'rent':
        return FixedPaymentCategory.rent;
      case 'vehicle':
        return FixedPaymentCategory.vehicle;
      case 'food':
        return FixedPaymentCategory.food;
      case 'tools':
        return FixedPaymentCategory.tools;
      case 'services':
        return FixedPaymentCategory.services;
      case 'taxes':
        return FixedPaymentCategory.taxes;
      default:
        return FixedPaymentCategory.other;
    }
  }
}
