import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gestr/app/dashboard/dasboard_page.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/domain/entities/invoice_model.dart';

mixin DashboardPageMixin on State<DashboardPage> {
  List<DateTime> lastMonths(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final m = DateTime(now.year, now.month - (count - 1 - i), 1);
      return DateTime(m.year, m.month, 1);
    });
  }

  String monthLabel(DateTime d) {
    const m = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return m[d.month - 1];
  }

  Map<DateTime, double> sumInvoicesNetByMonth(
    List<Invoice> invoices,
    List<DateTime> months,
  ) {
    final map = {for (final m in months) m: 0.0};
    for (final inv in invoices) {
      final key = DateTime(inv.date.year, inv.date.month, 1);
      if (map.containsKey(key)) {
        map[key] = (map[key] ?? 0) + inv.netAmount;
      }
    }
    return map;
  }

  Map<DateTime, double> sumInvoicesIvaByMonth(
    List<Invoice> invoices,
    List<DateTime> months,
  ) {
    final map = {for (final m in months) m: 0.0};
    for (final inv in invoices) {
      final key = DateTime(inv.date.year, inv.date.month, 1);
      if (map.containsKey(key)) {
        map[key] = (map[key] ?? 0) + inv.iva;
      }
    }
    return map;
  }

  Map<DateTime, double> sumFixedPaymentsByMonth(
    List<FixedPayment> payments,
    List<DateTime> months,
  ) {
    // Aproximación: imputar el pago al mes de su startDate
    final map = {for (final m in months) m: 0.0};
    for (final p in payments) {
      final key = DateTime(p.startDate.year, p.startDate.month, 1);
      if (map.containsKey(key)) {
        map[key] = (map[key] ?? 0) + p.amount;
      }
    }
    return map;
  }

  List<FlSpot> toSpots(List<DateTime> months, Map<DateTime, double> values) {
    return List.generate(
      months.length,
      (i) => FlSpot(i.toDouble(), (values[months[i]] ?? 0.0)),
    );
  }
}
