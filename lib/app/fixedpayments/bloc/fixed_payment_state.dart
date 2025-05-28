import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';

abstract class FixedPaymentState extends Equatable {
  const FixedPaymentState();

  @override
  List<Object?> get props => [];
}

class FixedPaymentInitial extends FixedPaymentState {}

class FixedPaymentLoading extends FixedPaymentState {}

class FixedPaymentLoaded extends FixedPaymentState {
  final List<FixedPayment> fixedPayments;

  const FixedPaymentLoaded(this.fixedPayments);

  @override
  List<Object?> get props => [fixedPayments];
}

class FixedPaymentError extends FixedPaymentState {
  final String message;

  const FixedPaymentError(this.message);

  @override
  List<Object?> get props => [message];
}
