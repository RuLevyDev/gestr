import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestr/app/tax/bloc/summary/summary_bloc.dart';
import 'package:gestr/app/tax/bloc/summary/summary_event.dart';
import 'package:gestr/app/tax/bloc/summary/summary_state.dart';
import 'package:gestr/app/tax/bloc/chart/chart_bloc.dart';
import 'package:gestr/app/tax/bloc/chart/chart_event.dart';
import 'package:gestr/app/tax/bloc/chart/chart_state.dart';
import 'package:gestr/app/tax/bloc/vat/vat_bloc.dart';
import 'package:gestr/app/tax/bloc/vat/vat_event.dart';
import 'package:gestr/app/tax/bloc/vat/vat_state.dart';
import 'package:gestr/app/tax/bloc/expenses_by_category/expenses_by_category_bloc.dart';
import 'package:gestr/app/tax/bloc/expenses_by_category/expenses_by_category_event.dart';
import 'package:gestr/app/tax/bloc/expenses_by_category/expenses_by_category_state.dart';
import 'package:gestr/app/tax/bloc/top_clients/top_clients_bloc.dart';
import 'package:gestr/app/tax/bloc/top_clients/top_clients_event.dart';
import 'package:gestr/app/tax/bloc/top_clients/top_clients_state.dart';
import 'package:gestr/app/tax/bloc/pre303/pre303_bloc.dart';
import 'package:gestr/app/tax/bloc/pre303/pre303_event.dart';
import 'package:gestr/app/tax/bloc/pre303/pre303_state.dart';
import 'package:gestr/app/tax/application/viewmodel/tax_summary_page_mixin.dart';
import 'package:gestr/domain/entities/tax_vat_breakdown.dart';
import 'package:gestr/domain/entities/tax_client_total.dart';
import 'package:gestr/domain/entities/tax_pre303.dart';
import 'package:gestr/domain/entities/tax_category_total.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';

class TaxSummaryPage extends StatefulWidget {
  const TaxSummaryPage({super.key});
  @override
  State<TaxSummaryPage> createState() => _TaxSummaryPageState();
}

class _TaxSummaryPageState extends State<TaxSummaryPage>
    with TaxSummaryPageMixin {
  bool _showYoY = false;
  bool _overlayYoY = false;
  bool _showFullMonth = false;

  @override
  void initState() {
    super.initState();
    context.read<SummaryBloc>().add(const SummaryEvent.fetch());
    context.read<ChartBloc>().add(const ChartEvent.fetch());
    final now = DateTime.now();
    final defaultRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
    );
    context.read<VatBloc>().add(VatEvent.setPeriod(defaultRange));
    context
        .read<ExpensesByCategoryBloc>()
        .add(ExpensesByCategoryEvent.setPeriod(defaultRange));
    context.read<TopClientsBloc>().add(TopClientsEvent.setPeriod(defaultRange));
    context.read<Pre303Bloc>().add(Pre303Event.setPeriod(defaultRange));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42.0, horizontal: 24),
      child: BlocBuilder<SummaryBloc, SummaryState>(
        builder: (context, s) {
          final range = (s is SummaryLoaded)
              ? s.range
              : DateTimeRange(start: DateTime.now(), end: DateTime.now());
          if (s is! SummaryLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = s.summary;
          final prev = s.previous;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Resumen fiscal',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      tooltip: 'Exportar CSV',
                      icon: const Icon(Icons.ios_share),
                      onPressed: () {
                        final ss = context.read<SummaryBloc>().state;
                        final cs = context.read<ChartBloc>().state;
                        if (ss is! SummaryLoaded || cs is! ChartLoaded) return;
                        exportCsvFromPieces(
                          range: ss.range,
                          summary: ss.summary,
                          previous: ss.previous,
                          labels: cs.labels,
                          monthlyIncome: cs.income,
                          monthlyExpenses: cs.expenses,
                        );
                      },
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Comparar con año anterior'),
                  value: _showYoY,
                  onChanged: (v) => setState(() => _showYoY = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      tooltip: _overlayYoY ? 'Ocultar YoY' : 'Superponer YoY',
                      icon: Icon(
                        _overlayYoY
                            ? Icons.timeline
                            : Icons.timeline_outlined,
                      ),
                      onPressed: () => setState(() => _overlayYoY = !_overlayYoY),
                    ),
                    buildPeriodMenu(
                      initial: range,
                      onChanged: (r) {
                        context.read<SummaryBloc>().add(SummaryEvent.setPeriod(r));
                        context.read<ChartBloc>().add(ChartEvent.setPeriod(r));
                        context.read<VatBloc>().add(VatEvent.setPeriod(r));
                        context
                            .read<ExpensesByCategoryBloc>()
                            .add(ExpensesByCategoryEvent.setPeriod(r));
                        context.read<TopClientsBloc>().add(TopClientsEvent.setPeriod(r));
                        context.read<Pre303Bloc>().add(Pre303Event.setPeriod(r));
                      },
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark
                        ? Colors.indigo.withAlpha(25)
                        : Colors.teal.withAlpha(25),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetricRow(
                        label: 'Ingresos',
                        value: summary.totalIncome,
                        previous: prev.totalIncome,
                        icon: Icons.trending_up,
                        color: isDark ? Colors.lightGreenAccent : Colors.green,
                        formatter: formatCurrency,
                      ),
                      const SizedBox(height: 8),
                      _MetricRow(
                        label: 'Gastos',
                        value: summary.totalExpenses,
                        previous: prev.totalExpenses,
                        icon: Icons.trending_down,
                        color: isDark ? Colors.redAccent : Colors.red,
                        formatter: formatCurrency,
                      ),
                      const SizedBox(height: 8),
                      _MetricRow(
                        label: 'Ingreso neto',
                        value: summary.totalIncome - summary.totalExpenses,
                        previous: prev.totalIncome - prev.totalExpenses,
                        icon: Icons.ssid_chart,
                        color: isDark ? Colors.lightGreenAccent : Colors.teal,
                        formatter: formatCurrency,
                        isBold: true,
                      ),
                      const Divider(height: 24),
                      _MetricRow(
                        label: 'IVA repercutido',
                        value: summary.vatCollected,
                        previous: prev.vatCollected,
                        icon: Icons.receipt_long,
                        color: isDark ? Colors.amberAccent : Colors.amber,
                        formatter: formatCurrency,
                      ),
                      const SizedBox(height: 8),
                      _MetricRow(
                        label: 'IVA soportado',
                        value: summary.vatPaid,
                        previous: prev.vatPaid,
                        icon: Icons.receipt,
                        color: isDark ? Colors.cyanAccent : Colors.cyan,
                        formatter: formatCurrency,
                      ),
                      const Divider(height: 24),
                      _MetricRow(
                        label: 'Resultado (IVA)',
                        value: summary.vatCollected - summary.vatPaid,
                        previous: prev.vatCollected - prev.vatPaid,
                        icon: Icons.balance,
                        color: isDark ? Colors.purpleAccent : Colors.deepPurple,
                        isBold: true,
                        formatter: formatCurrency,
                      ),
                      const Divider(height: 24),
                      _MetricRow(
                        label: 'Facturas',
                        value: summary.invoiceCount.toDouble(),
                        previous: prev.invoiceCount.toDouble(),
                        icon: Icons.receipt_long_outlined,
                        color: isDark ? Colors.blueAccent : Colors.blue,
                        formatter: (v) => v.toStringAsFixed(0),
                      ),
                      const SizedBox(height: 8),
                      _MetricRow(
                        label: 'Ticket medio',
                        value: summary.averageTicket,
                        previous: prev.averageTicket,
                        icon: Icons.payments_outlined,
                        color: isDark ? Colors.indigoAccent : Colors.indigo,
                        formatter: formatCurrency,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                BlocSelector<ChartBloc, ChartState, ({List<String> labels, List<double> income, List<double> expenses, List<double> yoyInc, List<double> yoyExp, DateTimeRange range})?>(
                  selector: (cs) {
                    if (cs is! ChartLoaded) return null;
                    return (
                      labels: cs.labels,
                      income: cs.income,
                      expenses: cs.expenses,
                      yoyInc: cs.yoyIncome,
                      yoyExp: cs.yoyExpenses,
                      range: cs.range,
                    );
                  },
                  builder: (context, data) {
                    if (data == null) {
                      return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
                    }
                    return buildMonthlyLineChartWithYoY(
                      labels: data.labels,
                      income: data.income,
                      expenses: data.expenses,
                      yoyIncome: data.yoyInc,
                      yoyExpenses: data.yoyExp,
                      showYoY: _showYoY || _overlayYoY,
                      range: data.range,
                      cutAtToday: !_showFullMonth,
                      onToggleCutAtToday: () => setState(() => _showFullMonth = !_showFullMonth),
                    );
                  },
                ),
                const SizedBox(height: 16),
                BlocSelector<VatBloc, VatState, VatBreakdown?>(
                  selector: (s) => s is VatLoaded ? s.vat : null,
                  builder: (context, vat) {
                    return BlocSelector<ExpensesByCategoryBloc, ExpensesByCategoryState, List<CategoryTotal>?>(
                      selector: (s) => s is ExpensesByCategoryLoaded ? s.totals : null,
                      builder: (context, totals) {
                        if (vat != null && totals != null) {
                          return _DonutsGlassCard(
                            vat: vat,
                            expensesByCategory: totals,
                            onTapCategory: (cat) => _showCategoryDetails(context, cat, range),
                          );
                        }
                        return const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                BlocSelector<TopClientsBloc, TopClientsState, List<ClientTotal>?>(
                  selector: (s) => s is TopClientsLoaded ? s.clients : null,
                  builder: (context, clients) {
                    if (clients != null) return _TopClientsList(clients: clients);
                    return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                  },
                ),
                if (_showYoY)
                  BlocSelector<ChartBloc, ChartState, ({double inc, double exp, double yoyInc, double yoyExp})?>(
                    selector: (cs) {
                      if (cs is! ChartLoaded) return null;
                      double sum(List<double> a) => a.isEmpty ? 0 : a.reduce((x, y) => x + y);
                      return (
                        inc: sum(cs.income),
                        exp: sum(cs.expenses),
                        yoyInc: sum(cs.yoyIncome),
                        yoyExp: sum(cs.yoyExpenses),
                      );
                    },
                    builder: (context, yo) {
                      if (yo == null) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'Interanual (mismo periodo año anterior)',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDark
                                  ? Colors.blueGrey.withAlpha(25)
                                  : Colors.blue.withAlpha(25),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _MetricRow(
                                  label: 'Ingresos (YoY)',
                                  value: yo.inc,
                                  previous: yo.yoyInc,
                                  icon: Icons.trending_up,
                                  color: Colors.teal,
                                  formatter: formatCurrency,
                                ),
                                const SizedBox(height: 8),
                                _MetricRow(
                                  label: 'Gastos (YoY)',
                                  value: yo.exp,
                                  previous: yo.yoyExp,
                                  icon: Icons.trending_down,
                                  color: Colors.deepOrange,
                                  formatter: formatCurrency,
                                ),
                                const SizedBox(height: 8),
                                _MetricRow(
                                  label: 'Ingreso neto (YoY)',
                                  value: yo.inc - yo.exp,
                                  previous: yo.yoyInc - yo.yoyExp,
                                  icon: Icons.ssid_chart,
                                  color: Colors.indigo,
                                  formatter: formatCurrency,
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 16),
                BlocSelector<Pre303Bloc, Pre303State, Pre303Summary?>(
                  selector: (s) => s is Pre303Loaded ? s.pre303 : null,
                  builder: (context, pre) {
                    if (pre != null) return _Pre303Card(summary: pre);
                    return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCategoryDetails(
    BuildContext context,
    FixedPaymentCategory cat,
    DateTimeRange range,
  ) {
    final fpState = context.read<FixedPaymentBloc>().state;
    if (fpState is! FixedPaymentLoaded) return;
    final details = <_PaymentDetail>[];
    for (final p in fpState.fixedPayments.where((p) => p.category == cat)) {
      final occs = _occurrencesWithin(p, range);
      if (occs.isEmpty) continue;
      details.add(
        _PaymentDetail(
          payment: p,
          occurrences: occs.length,
          total: p.amount * occs.length,
        ),
      );
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle ${cat.nameEs}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (details.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No hay pagos para este periodo.'),
              )
            else ...details.map(
              (d) => ListTile(
                dense: true,
                title: Text(d.payment.title),
                subtitle: Text(
                  '${d.payment.supplier ?? ''} - ${d.payment.frequency.name} - ${d.occurrences} ocurr.',
                ),
                trailing: Text('${d.total.toStringAsFixed(2)} EUR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  List<DateTime> _occurrencesWithin(FixedPayment p, DateTimeRange range) {
    final from = range.start;
    final to = range.end;
    final occs = <DateTime>[];
    DateTime current = p.startDate;
    while (current.isBefore(from)) {
      current = _nextOccurrence(current, p.frequency);
      if (current.isAfter(to)) return occs;
    }
    while (!current.isAfter(to)) {
      occs.add(current);
      current = _nextOccurrence(current, p.frequency);
    }
    return occs;
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
        return DateTime(d.year, d.month + 1, d.day);
    }
  }
}

class _DonutsGlassCard extends StatelessWidget {
  final VatBreakdown vat;
  final List<CategoryTotal> expensesByCategory;
  final void Function(FixedPaymentCategory category)? onTapCategory;
  const _DonutsGlassCard({
    required this.vat,
    required this.expensesByCategory,
    this.onTapCategory,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.purpleAccent.withValues(alpha: 0.08)
                : Colors.lightBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 22,
                      child: Text(
                        'IVA por tipo',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: _VatDonut(breakdown: vat, chartHeight: 110),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 22,
                      child: Text(
                        'Gasto categoría',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: _ExpenseByCategoryDonut(
                        totals: expensesByCategory,
                        onTapCategory: onTapCategory,
                        chartHeight: 110,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VatDonut extends StatelessWidget {
  final VatBreakdown breakdown;
  final double chartHeight;
  const _VatDonut({required this.breakdown, this.chartHeight = 180});
  @override
  Widget build(BuildContext context) {
    final total = breakdown.totalBase + breakdown.totalIva;
    if (total == 0) return const SizedBox.shrink();
    final sections = [
      _slice('21%', breakdown.base21 + breakdown.iva21, Colors.teal),
      _slice('10%', breakdown.base10 + breakdown.iva10, Colors.orange),
      _slice('4%', breakdown.base4 + breakdown.iva4, Colors.purple),
      _slice('0%', breakdown.base0, Colors.grey),
    ].where((e) => e.value > 0).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: chartHeight,
          child: PieChart(
            PieChartData(
              sections: sections
                  .map(
                    (e) => PieChartSectionData(
                      color: e.color,
                      value: e.value,
                      title: e.label,
                      radius: 18,
                      titleStyle: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white),
                    ),
                  )
                  .toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 12,
            ),
          ),
        ),
      ],
    );
  }
  _Slice _slice(String label, double value, Color color) => _Slice(label, value, color);
}

class _Slice {
  final String label;
  final double value;
  final Color color;
  _Slice(this.label, this.value, this.color);
}

class _TopClientsList extends StatelessWidget {
  final List<ClientTotal> clients;
  const _TopClientsList({required this.clients});
  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top clientes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...clients.map(
          (c) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(c.client),
            trailing: Text('${c.total.toStringAsFixed(2)} EUR'),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _Pre303Card extends StatelessWidget {
  final Pre303Summary summary;
  const _Pre303Card({required this.summary});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modelo 303 (IVA)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _row('Base 21%', summary.base21),
          _row('IVA 21%', summary.iva21),
          _row('Base 10%', summary.base10),
          _row('IVA 10%', summary.iva10),
          _row('Base 4%', summary.base4),
          _row('IVA 4%', summary.iva4),
          _row('Exentas/0%', summary.base0),
          const Divider(),
          _row('IVA devengado', summary.totalDevengadoIva, bold: true),
          _row('IVA soportado (bruto)', summary.totalSoportadoIva),
          _row('Prorrata estimada', summary.prorrataPct, suffix: ' %'),
          _row('Ajuste prorrata', summary.ajusteProrrata),
          _row('IVA soportado ajustado', summary.soportadoAjustado, bold: true),
          const SizedBox(height: 6),
          _row('Resultado', summary.resultado, bold: true),
        ],
      ),
    );
  }
  Widget _row(String label, double value, {bool bold = false, String suffix = ' EUR'}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${value.toStringAsFixed(2)}$suffix', style: style),
        ],
      ),
    );
  }
}

class _ExpenseByCategoryDonut extends StatelessWidget {
  final List<CategoryTotal> totals;
  final double chartHeight;
  final void Function(FixedPaymentCategory category)? onTapCategory;
  const _ExpenseByCategoryDonut({
    required this.totals,
    this.onTapCategory,
    this.chartHeight = 180,
  });
  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) return const SizedBox.shrink();
    final colors = {
      FixedPaymentCategory.utilities: Colors.teal,
      FixedPaymentCategory.rent: Colors.orange,
      FixedPaymentCategory.vehicle: Colors.indigo,
      FixedPaymentCategory.food: Colors.pink,
      FixedPaymentCategory.tools: Colors.brown,
      FixedPaymentCategory.services: Colors.cyan,
      FixedPaymentCategory.taxes: Colors.redAccent,
      FixedPaymentCategory.other: Colors.grey,
    };
    final sections = totals
        .map(
          (t) => PieChartSectionData(
            color: colors[t.category] ?? Colors.grey,
            value: t.total,
            title: t.category.nameEs,
            radius: 20,
            titleStyle: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white),
          ),
        )
        .toList();
    return SizedBox(
      height: chartHeight,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 1,
          centerSpaceRadius: 12,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              if (event is! FlTapUpEvent) return;
              final idx = response?.touchedSection?.touchedSectionIndex;
              if (idx == null) return;
              if (idx >= 0 && idx < totals.length) {
                onTapCategory?.call(totals[idx].category);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _PaymentDetail {
  final FixedPayment payment;
  final int occurrences;
  final double total;
  const _PaymentDetail({
    required this.payment,
    required this.occurrences,
    required this.total,
  });
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final double? previous;
  final IconData icon;
  final Color color;
  final bool isBold;
  final String Function(double) formatter;
  const _MetricRow({
    required this.label,
    required this.value,
    this.previous,
    required this.icon,
    required this.color,
    required this.formatter,
    this.isBold = false,
  });
  @override
  Widget build(BuildContext context) {
    final textStyle = isBold
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.titleMedium;
    final pct = _percentDelta(previous, value);
    final deltaColor =
        pct == null ? Colors.grey : (pct >= 0 ? Colors.green : Colors.red);
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: textStyle)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatter(value),
              style: textStyle?.copyWith(
                fontWeight: isBold ? FontWeight.bold : null,
              ),
            ),
            if (previous != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (pct ?? 0) >= 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 12,
                    color: deltaColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    pct == null ? '-' : '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(color: deltaColor, fontSize: 10),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
  double? _percentDelta(double? prev, double current) {
    if (prev == null) return null;
    if (prev == 0) {
      if (current == 0) return 0;
      return null;
    }
    return ((current - prev) / prev) * 100.0;
  }
}
