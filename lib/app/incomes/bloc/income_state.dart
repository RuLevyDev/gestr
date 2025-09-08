import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/income.dart';

abstract class IncomeState extends Equatable {
  const IncomeState();
  @override
  List<Object?> get props => [];
}

class IncomeInitial extends IncomeState {}

class IncomeLoading extends IncomeState {}

class IncomeLoaded extends IncomeState {
  final List<Income> incomes;
  const IncomeLoaded(this.incomes);
  @override
  List<Object?> get props => [incomes];
}

class IncomeError extends IncomeState {
  final String message;
  const IncomeError(this.message);
  @override
  List<Object?> get props => [message];
}
