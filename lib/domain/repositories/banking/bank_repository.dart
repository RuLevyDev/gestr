import 'package:gestr/domain/entities/bank_transaction.dart';

abstract class BankRepository {
  Future<List<BankTransaction>> fetchTransactions(String userId);
  Future<void> linkWithIncome(
    String userId,
    String transactionId,
    String incomeId,
  );
}
