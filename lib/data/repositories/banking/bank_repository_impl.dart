import 'package:gestr/data/banking/bank_service.dart';
import 'package:gestr/domain/entities/bank_transaction.dart';
import 'package:gestr/domain/repositories/banking/bank_repository.dart';

class BankRepositoryImpl implements BankRepository {
  final BankService service;
  BankRepositoryImpl(this.service);

  @override
  Future<List<BankTransaction>> fetchTransactions(String userId) {
    // In a real implementation userId would map to an access token
    return service.fetchTransactions(userId);
  }

  @override
  Future<void> linkWithIncome(
    String userId,
    String transactionId,
    String incomeId,
  ) async {
    // Placeholder for linking logic
    return;
  }
}
