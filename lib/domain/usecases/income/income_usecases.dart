import 'package:gestr/domain/entities/income.dart';
import 'package:gestr/domain/repositories/income/income_repository.dart';

class IncomeUseCases {
  final IncomeRepository _repo;
  IncomeUseCases(this._repo);

  Future<List<Income>> fetch(String userId) => _repo.getIncomes(userId);
  Future<void> create(String userId, Income income) =>
      _repo.createIncome(userId, income);
  Future<void> update(String userId, Income income) =>
      _repo.updateIncome(userId, income);
  Future<Income> voidIncome(
    String userId,
    String id, {
    String? voidedBy,
    String? voidReason,
  }) =>
      _repo.voidIncome(userId, id, voidedBy: voidedBy, voidReason: voidReason);
  Future<Income?> getById(String userId, String id) =>
      _repo.getIncomeById(userId, id);
}
