import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/tax_category_total.dart';

abstract class ExpensesByCategoryState extends Equatable {
  const ExpensesByCategoryState();
  @override
  List<Object?> get props => [];
}

class ExpensesByCategoryInitial extends ExpensesByCategoryState {}
class ExpensesByCategoryLoading extends ExpensesByCategoryState {}
class ExpensesByCategoryLoaded extends ExpensesByCategoryState {
  final List<CategoryTotal> totals;
  const ExpensesByCategoryLoaded(this.totals);
  @override
  List<Object?> get props => [totals];
}
class ExpensesByCategoryError extends ExpensesByCategoryState {
  final String message;
  const ExpensesByCategoryError(this.message);
  @override
  List<Object?> get props => [message];
}

