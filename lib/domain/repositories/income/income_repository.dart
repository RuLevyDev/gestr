import 'package:gestr/domain/entities/income.dart';

abstract class IncomeRepository {
  Future<List<Income>> getIncomes(String userId);
  Future<void> createIncome(String userId, Income income);
  Future<Income> voidIncome(
    String userId,
    String incomeId, {
    String? voidedBy,
    String? voidReason,
  });
  Future<void> updateIncome(String userId, Income income);
  Future<Income?> getIncomeById(String userId, String id);
}
