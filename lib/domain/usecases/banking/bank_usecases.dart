import 'package:gestr/domain/entities/bank_transaction.dart';
import 'package:gestr/domain/repositories/banking/bank_repository.dart';

class BankUseCases {
  final BankRepository _repo;
  BankUseCases(this._repo);

  Future<List<BankTransaction>> fetch(String userId) =>
      _repo.fetchTransactions(userId);

  Future<void> link(String userId, String transactionId, String incomeId) =>
      _repo.linkWithIncome(userId, transactionId, incomeId);
}
