import 'package:gestr/domain/entities/tax_summary_model.dart';
import 'package:gestr/domain/repositories/invoice/invoice_reposiroty.dart';
import 'package:gestr/domain/repositories/income/income_repository.dart';
import 'package:gestr/domain/repositories/fixedpayments/fixed_payments_repository.dart';
import 'package:gestr/domain/repositories/tax/tax_summary_repository.dart';
import 'package:gestr/domain/entities/tax_vat_breakdown.dart';
import 'package:gestr/domain/entities/tax_client_total.dart';
import 'package:gestr/domain/entities/tax_pre303.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/domain/entities/tax_category_total.dart';

class TaxSummaryRepositoryImpl implements TaxSummaryRepository {
  final InvoiceRepository invoiceRepository;
  final IncomeRepository incomeRepository;
  final FixedPaymentRepository fixedPaymentRepository;

  TaxSummaryRepositoryImpl(
    this.invoiceRepository,
    this.fixedPaymentRepository,
    this.incomeRepository,
  );

  @override
  Future<TaxSummary> getSummary(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final invoices = await invoiceRepository.getInvoices(userId);
    final incomes = await incomeRepository.getIncomes(userId);
    final fixedPayments = await fixedPaymentRepository.getFixedPayments(userId);

    bool inRange(DateTime d) {
      final sOk = start == null || !d.isBefore(start);
      final eOk = end == null || !d.isAfter(end);
      return sOk && eOk;
    }

    final filteredInvoices =
        (start == null && end == null)
            ? invoices
            : invoices.where((i) => inRange(i.date)).toList();
    final filteredFixedPayments = fixedPayments;
    final filteredIncomes =
        (start == null && end == null)
            ? incomes
            : incomes.where((i) => inRange(i.date)).toList();

    final totalIncomeFromInvoices = filteredInvoices.fold<double>(
      0,
      (sum, i) => sum + i.netAmount,
    );
    final totalIncomeFromIncomes = filteredIncomes.fold<double>(
      0,
      (sum, inc) => sum + inc.amount,
    );
    final totalIncome = totalIncomeFromInvoices + totalIncomeFromIncomes;
    final vatCollected = filteredInvoices.fold<double>(
      0,
      (sum, i) => sum + i.iva,
    );
    final invoiceCount = filteredInvoices.length;
    final averageTicket = invoiceCount > 0 ? totalIncome / invoiceCount : 0.0;

    double totalExpenses = 0;
    double vatPaid = 0;
    for (final p in filteredFixedPayments) {
      // Expandir ocurrencias por frecuencia dentro del rango
      final occs = _occurrencesWithin(p, start, end);
      for (final _ in occs) {
        totalExpenses += p.amount;
        if (!p.deductible || p.vatRate <= 0) continue;
        if (p.amountIsGross) {
          final base = p.amount / (1 + p.vatRate);
          vatPaid += p.amount - base;
        } else {
          vatPaid += p.amount * p.vatRate;
        }
      }
    }

    return TaxSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      vatCollected: vatCollected,
      vatPaid: vatPaid,
      invoiceCount: invoiceCount,
      averageTicket: averageTicket,
    );
  }

  Iterable<DateTime> _occurrencesWithin(
    FixedPayment p,
    DateTime? start,
    DateTime? end,
  ) sync* {
    final from = start ?? p.startDate;
    final to = end ?? DateTime.now();
    DateTime current = p.startDate;
    if (current.isBefore(from)) {
      while (current.isBefore(from)) {
        current = _nextOccurrence(current, p.frequency);
      }
    }
    while (!current.isAfter(to)) {
      if (!current.isBefore(from)) yield current;
      current = _nextOccurrence(current, p.frequency);
    }
  }

  DateTime _nextOccurrence(DateTime d, FixedPaymentFrequency f) {
    switch (f) {
      case FixedPaymentFrequency.weekly:
        return d.add(const Duration(days: 7));
      case FixedPaymentFrequency.monthly:
        return DateTime(d.year, d.month + 1, d.day);
      case FixedPaymentFrequency.quarterly:
        return DateTime(d.year, d.month + 3, d.day);
      case FixedPaymentFrequency.fourMonthly:
        return DateTime(d.year, d.month + 4, d.day);
      case FixedPaymentFrequency.semiYearly:
        return DateTime(d.year, d.month + 6, d.day);
      case FixedPaymentFrequency.yearly:
        return DateTime(d.year + 1, d.month, d.day);
      case FixedPaymentFrequency.custom:
        return DateTime(d.year, d.month + 1, d.day); // aproximación
    }
  }

  int _closestRate(double ratio) {
    // ratio = iva / netAmount * 100
    final candidates = [0, 4, 10, 21];
    var best = 0;
    var bestDiff = double.infinity;
    for (final r in candidates) {
      final d = (ratio - r).abs();
      if (d < bestDiff) {
        best = r;
        bestDiff = d;
      }
    }
    return best;
  }

  @override
  Future<VatBreakdown> getVatBreakdown(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final invoices = await invoiceRepository.getInvoices(userId);
    bool inRange(DateTime d) {
      final sOk = start == null || !d.isBefore(start);
      final eOk = end == null || !d.isAfter(end);
      return sOk && eOk;
    }

    final filtered =
        (start == null && end == null)
            ? invoices
            : invoices.where((i) => inRange(i.date)).toList();

    double base21 = 0,
        iva21 = 0,
        base10 = 0,
        iva10 = 0,
        base4 = 0,
        iva4 = 0,
        base0 = 0;
    for (final inv in filtered) {
      final net = inv.netAmount;
      final vat = inv.iva;
      final rate = net == 0 ? 0 : _closestRate((vat / net) * 100);
      switch (rate) {
        case 21:
          base21 += net;
          iva21 += vat;
          break;
        case 10:
          base10 += net;
          iva10 += vat;
          break;
        case 4:
          base4 += net;
          iva4 += vat;
          break;
        default:
          base0 += net;
      }
    }
    return VatBreakdown(
      base21: base21,
      iva21: iva21,
      base10: base10,
      iva10: iva10,
      base4: base4,
      iva4: iva4,
      base0: base0,
    );
  }

  @override
  Future<List<ClientTotal>> getTopClients(
    String userId, {
    DateTime? start,
    DateTime? end,
    int limit = 5,
  }) async {
    final invoices = await invoiceRepository.getInvoices(userId);
    bool inRange(DateTime d) {
      final sOk = start == null || !d.isBefore(start);
      final eOk = end == null || !d.isAfter(end);
      return sOk && eOk;
    }

    final filtered =
        (start == null && end == null)
            ? invoices
            : invoices.where((i) => inRange(i.date)).toList();
    final Map<String, double> totals = {};
    for (final inv in filtered) {
      final key = (inv.receiver ?? '—');
      totals[key] = (totals[key] ?? 0) + inv.netAmount;
    }
    final list =
        totals.entries
            .map((e) => ClientTotal(client: e.key, total: e.value))
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));
    return list.take(limit).toList();
  }

  @override
  Future<Pre303Summary> getPre303(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final vat = await getVatBreakdown(userId, start: start, end: end);
    final totalBase = vat.totalBase;
    final totalIva = vat.totalIva;

    // IVA soportado desde pagos fijos deducibles
    final payments = await fixedPaymentRepository.getFixedPayments(userId);
    bool inRange(DateTime d) {
      final sOk = start == null || !d.isBefore(start);
      final eOk = end == null || !d.isAfter(end);
      return sOk && eOk;
    }

    final filtered =
        (start == null && end == null)
            ? payments
            : payments.where((p) => inRange(p.startDate)).toList();
    double supported = 0;
    for (final p in filtered) {
      if (!p.deductible || p.vatRate <= 0) continue;
      if (p.amountIsGross) {
        final base = p.amount / (1 + p.vatRate);
        supported += p.amount - base;
      } else {
        supported += p.amount * p.vatRate;
      }
    }

    // Prorrata estimada: base con IVA / base total (simple)
    final baseConIva = vat.base21 + vat.base10 + vat.base4;
    final baseTotal = baseConIva + vat.base0;
    final prorrata = baseTotal > 0 ? (baseConIva / baseTotal) : 1.0;
    final soportadoAjustado = supported * prorrata;

    return Pre303Summary(
      base21: vat.base21,
      iva21: vat.iva21,
      base10: vat.base10,
      iva10: vat.iva10,
      base4: vat.base4,
      iva4: vat.iva4,
      base0: vat.base0,
      totalDevengadoBase: totalBase,
      totalDevengadoIva: totalIva,
      totalSoportadoIva: supported,
      prorrata: prorrata,
      soportadoAjustado: soportadoAjustado,
    );
  }

  @override
  Future<List<CategoryTotal>> getExpensesByCategory(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final payments = await fixedPaymentRepository.getFixedPayments(userId);
    final Map<FixedPaymentCategory, double> totals = {
      for (final c in FixedPaymentCategory.values) c: 0.0,
    };
    for (final p in payments) {
      final occs = _occurrencesWithin(p, start, end);
      var count = 0;
      for (final _ in occs) {
        count++;
      }
      if (count > 0) {
        totals[p.category] = (totals[p.category] ?? 0) + p.amount * count;
      }
    }
    final list = totals.entries
        .where((e) => e.value > 0)
        .map((e) => CategoryTotal(e.key, e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }
}
