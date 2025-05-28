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

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FixedPayment(
          id: doc.id,
          title: data['title'],
          amount: (data['amount'] ?? 0).toDouble(),
          startDate: (data['startDate'] as Timestamp).toDate(),
          frequency: _parseStatus(data['frequency']),
          description: data['description'],
          imageUrl: data['imageUrl'],
        );
      }).toList();
    } catch (e) {
      throw Exception("Error al obtener los pagos fijos: $e");
    }
  }

  @override
  Future<void> createFixedPayment(String userId, FixedPayment payment) async {
    try {
      String? imageUrl;

      if (payment.image != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = storage.ref().child('fixedPayments/$fileName');
        await ref.putFile(payment.image!);
        imageUrl = await ref.getDownloadURL();
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
            'imageUrl': imageUrl,
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

        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = storage.ref().child('fixedPayments/$fileName');
        await ref.putFile(payment.image!);
        imageUrl = await ref.getDownloadURL();
      }

      await docRef.update({
        'title': payment.title,
        'amount': payment.amount,
        'startDate': payment.startDate,
        'frequency': payment.frequency.name,
        'description': payment.description,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      throw Exception("Error al actualizar el pago fijo: $e");
    }
  }

  @override
  Future<void> deleteFixedPayment(String userId, String paymentId) async {
    try {
      final docRef = firestore
          .collection('users')
          .doc(userId)
          .collection('fixedPayments')
          .doc(paymentId);

      final doc = await docRef.get();

      if (doc.exists && doc.data()!['imageUrl'] != null) {
        final imageUrl = doc.data()!['imageUrl'] as String;
        final ref = storage.refFromURL(imageUrl);
        await ref.delete();
      }

      await docRef.delete();
    } catch (e) {
      throw Exception("Error al eliminar el pago fijo: $e");
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
      return FixedPayment(
        id: doc.id,
        title: data['title'],
        amount: (data['amount'] ?? 0).toDouble(),
        startDate: (data['startDate'] as Timestamp).toDate(),
        frequency: _parseStatus(data['frequency']),
        description: data['description'],
        imageUrl: data['imageUrl'],
      );
    } catch (e) {
      throw Exception("Error al obtener el pago fijo por ID: $e");
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
}
