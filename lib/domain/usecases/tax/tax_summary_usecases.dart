import 'package:gestr/domain/entities/tax_summary_model.dart';
import 'package:gestr/domain/entities/tax_vat_breakdown.dart';
import 'package:gestr/domain/entities/tax_client_total.dart';
import 'package:gestr/domain/entities/tax_pre303.dart';
import 'package:gestr/domain/entities/tax_category_total.dart';
import 'package:gestr/domain/repositories/tax/tax_summary_repository.dart';

class TaxSummaryUseCases {
  final TaxSummaryRepository _repository;

  TaxSummaryUseCases(this._repository);

  Future<TaxSummary> fetchSummary(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) {
    return _repository.getSummary(userId, start: start, end: end);
  }

  Future<VatBreakdown> vatBreakdown(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) => _repository.getVatBreakdown(userId, start: start, end: end);

  Future<List<ClientTotal>> topClients(
    String userId, {
    DateTime? start,
    DateTime? end,
    int limit = 5,
  }) => _repository.getTopClients(userId, start: start, end: end, limit: limit);

  Future<Pre303Summary> pre303(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) => _repository.getPre303(userId, start: start, end: end);

  Future<List<CategoryTotal>> expensesByCategory(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) => _repository.getExpensesByCategory(userId, start: start, end: end);
}
