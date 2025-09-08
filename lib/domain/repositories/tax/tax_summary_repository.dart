import 'package:gestr/domain/entities/tax_summary_model.dart';
import 'package:gestr/domain/entities/tax_vat_breakdown.dart';
import 'package:gestr/domain/entities/tax_client_total.dart';
import 'package:gestr/domain/entities/tax_pre303.dart';
import 'package:gestr/domain/entities/tax_category_total.dart';

abstract class TaxSummaryRepository {
  Future<TaxSummary> getSummary(
    String userId, {
    DateTime? start,
    DateTime? end,
  });
  Future<VatBreakdown> getVatBreakdown(
    String userId, {
    DateTime? start,
    DateTime? end,
  });
  Future<List<ClientTotal>> getTopClients(
    String userId, {
    DateTime? start,
    DateTime? end,
    int limit,
  });
  Future<Pre303Summary> getPre303(
    String userId, {
    DateTime? start,
    DateTime? end,
  });
  Future<List<CategoryTotal>> getExpensesByCategory(
    String userId, {
    DateTime? start,
    DateTime? end,
  });
}
