import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/tax_vat_breakdown.dart';

abstract class VatState extends Equatable {
  const VatState();
  @override
  List<Object?> get props => [];
}

class VatInitial extends VatState {}

class VatLoading extends VatState {}

class VatLoaded extends VatState {
  final VatBreakdown vat;
  const VatLoaded(this.vat);
  @override
  List<Object?> get props => [vat];
}

class VatError extends VatState {
  final String message;
  const VatError(this.message);
  @override
  List<Object?> get props => [message];
}
