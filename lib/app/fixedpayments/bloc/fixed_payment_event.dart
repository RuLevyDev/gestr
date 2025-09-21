import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';

enum FixedPaymentEventType { fetch, refresh, create, update, delete, getById }

class FixedPaymentEvent extends Equatable {
  final FixedPaymentEventType type;
  final FixedPayment? fixedPayment;
  final String? paymentId;
  final String? voidReason;

  const FixedPaymentEvent._(
    this.type, {
    this.fixedPayment,
    this.paymentId,
    this.voidReason,
  });

  const FixedPaymentEvent.getById(String paymentId)
    : this._(FixedPaymentEventType.getById, paymentId: paymentId);

  const FixedPaymentEvent.fetch() : this._(FixedPaymentEventType.fetch);

  const FixedPaymentEvent.refresh() : this._(FixedPaymentEventType.refresh);

  const FixedPaymentEvent.create(FixedPayment fixedPayment)
    : this._(FixedPaymentEventType.create, fixedPayment: fixedPayment);
  const FixedPaymentEvent.update(FixedPayment fixedPayment)
    : this._(FixedPaymentEventType.update, fixedPayment: fixedPayment);

  const FixedPaymentEvent.delete(String paymentId, {String? voidReason})
    : this._(
        FixedPaymentEventType.delete,
        paymentId: paymentId,
        voidReason: voidReason,
      );

  @override
  List<Object?> get props => [type, fixedPayment, paymentId, voidReason];
}
