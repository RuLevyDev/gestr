import 'package:gestr/domain/entities/income.dart';

abstract class IncomeRepository {
  Future<List<Income>> getIncomes(String userId);
  Future<void> createIncome(String userId, Income income);
  Future<void> deleteIncome(String userId, String incomeId);
  Future<void> updateIncome(String userId, Income income);
  Future<Income?> getIncomeById(String userId, String id);
}

