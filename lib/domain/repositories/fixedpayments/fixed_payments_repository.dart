import 'package:gestr/domain/entities/fixed_payments_model.dart';

abstract class FixedPaymentRepository {
  Future<List<FixedPayment>> getFixedPayments(String userId);
  Future<void> createFixedPayment(String userId, FixedPayment payment);
  Future<void> updateFixedPayment(String userId, FixedPayment payment);
  Future<FixedPayment> voidFixedPayment(
    String userId,
    String paymentId, {
    String? voidedBy,
    String? voidReason,
  });
  Future<FixedPayment?> getFixedPaymentById(String userId, String id);
}
