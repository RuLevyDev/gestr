import 'package:gestr/domain/entities/fixed_payments_model.dart';

abstract class FixedPaymentRepository {
  Future<List<FixedPayment>> getFixedPayments(String userId);
  Future<void> createFixedPayment(String userId, FixedPayment payment);
  Future<void> updateFixedPayment(String userId, FixedPayment payment);
  Future<void> deleteFixedPayment(String userId, String paymentId);
  Future<FixedPayment?> getFixedPaymentById(String userId, String id);
}
