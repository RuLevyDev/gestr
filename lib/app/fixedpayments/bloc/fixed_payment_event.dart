import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';

enum FixedPaymentEventType { fetch, refresh, create, update, delete, getById }

class FixedPaymentEvent extends Equatable {
  final FixedPaymentEventType type;
  final FixedPayment? fixedPayment;
  final String? paymentId;

  const FixedPaymentEvent._(this.type, {this.fixedPayment, this.paymentId});

  const FixedPaymentEvent.getById(String paymentId)
    : this._(FixedPaymentEventType.getById, paymentId: paymentId);

  const FixedPaymentEvent.fetch() : this._(FixedPaymentEventType.fetch);

  const FixedPaymentEvent.refresh() : this._(FixedPaymentEventType.refresh);

  const FixedPaymentEvent.create(FixedPayment fixedPayment)
    : this._(FixedPaymentEventType.create, fixedPayment: fixedPayment);
  const FixedPaymentEvent.update(FixedPayment fixedPayment)
    : this._(FixedPaymentEventType.update, fixedPayment: fixedPayment);

  const FixedPaymentEvent.delete(String paymentId)
    : this._(FixedPaymentEventType.delete, paymentId: paymentId);

  @override
  List<Object?> get props => [type, fixedPayment, paymentId];
}
