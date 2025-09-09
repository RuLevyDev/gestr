import 'package:equatable/equatable.dart';

enum BankTransactionEventType { fetch, link }

class BankTransactionEvent extends Equatable {
  final BankTransactionEventType type;
  final String? transactionId;
  final String? incomeId;

  const BankTransactionEvent._(this.type, {this.transactionId, this.incomeId});
  const BankTransactionEvent.fetch() : this._(BankTransactionEventType.fetch);
  const BankTransactionEvent.link(String transactionId, String incomeId)
    : this._(
        BankTransactionEventType.link,
        transactionId: transactionId,
        incomeId: incomeId,
      );

  @override
  List<Object?> get props => [type, transactionId, incomeId];
}
