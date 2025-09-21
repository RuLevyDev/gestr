import 'package:gestr/domain/entities/fixed_payments_model.dart';

import 'package:gestr/domain/repositories/fixedpayments/fixed_payments_repository.dart';

class FixedPaymentUseCases {
  final FixedPaymentRepository _repository;

  FixedPaymentUseCases(this._repository);

  Future<List<FixedPayment>> fetchFixedPayments(String userId) {
    return _repository.getFixedPayments(userId);
  }

  Future<void> createFixedPayment(String userId, FixedPayment payment) {
    return _repository.createFixedPayment(userId, payment);
  }

  Future<void> updateFixedPayment(String userId, FixedPayment payment) {
    return _repository.updateFixedPayment(userId, payment);
  }

  Future<FixedPayment> voidFixedPayment(
    String userId,
    String paymentId, {
    String? voidedBy,
    String? voidReason,
  }) {
    return _repository.voidFixedPayment(
      userId,
      paymentId,
      voidedBy: voidedBy,
      voidReason: voidReason,
    );
  }

  Future<FixedPayment?> getFixedPaymentById(String userId, String id) {
    return _repository.getFixedPaymentById(userId, id);
  }
}
