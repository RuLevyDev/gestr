import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/bank_transaction.dart';

abstract class BankTransactionState extends Equatable {
  const BankTransactionState();
  @override
  List<Object?> get props => [];
}

class BankTransactionInitial extends BankTransactionState {}

class BankTransactionLoading extends BankTransactionState {}

class BankTransactionLoaded extends BankTransactionState {
  final List<BankTransaction> transactions;
  const BankTransactionLoaded(this.transactions);
  @override
  List<Object?> get props => [transactions];
}

class BankTransactionError extends BankTransactionState {
  final String message;
  const BankTransactionError(this.message);
  @override
  List<Object?> get props => [message];
}
