import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gestr/domain/entities/tax_summary_model.dart';

import 'package:gestr/app/tax/application/view/tax_summary_page.dart';

mixin TaxSummaryPageMixin on State<TaxSummaryPage> {
  // Variante sin TaxSummaryLoaded: piezas sueltas
  Future<void> exportCsvFromPieces({
    required DateTimeRange range,
    required TaxSummary summary,
    required TaxSummary previous,
    required List<String> labels,
    required List<double> monthlyIncome,
    required List<double> monthlyExpenses,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'Periodo,${range.start.toIso8601String()} - ${range.end.toIso8601String()}',
    );
    buffer.writeln('Metrica,Valor');
    buffer.writeln('Ingresos,${summary.totalIncome.toStringAsFixed(2)}');
    buffer.writeln('Gastos,${summary.totalExpenses.toStringAsFixed(2)}');
    buffer.writeln(
      'IVA repercutido,${summary.vatCollected.toStringAsFixed(2)}',
    );
    buffer.writeln('IVA soportado,${summary.vatPaid.toStringAsFixed(2)}');
    buffer.writeln(
      'Ingreso neto,${(summary.totalIncome - summary.totalExpenses).toStringAsFixed(2)}',
    );
    buffer.writeln('Facturas,${summary.invoiceCount}');
    buffer.writeln('Ticket medio,${summary.averageTicket.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('Mes,Ingresos,Gastos');
    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final inc =
          i < monthlyIncome.length
              ? monthlyIncome[i].toStringAsFixed(2)
              : '0.00';
      final exp =
          i < monthlyExpenses.length
              ? monthlyExpenses[i].toStringAsFixed(2)
              : '0.00';
      buffer.writeln('$label,$inc,$exp');
    }
    final csv = buffer.toString();
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await SharePlus.instance.share(
      ShareParams(
        text: 'Resumen fiscal exportado',
        subject: 'Resumen fiscal (${range.start.year}-${range.start.month})',
        files: [
          XFile.fromData(
            bytes,
            name: 'resumen_fiscal.csv',
            mimeType: 'text/csv',
          ),
        ],
      ),
    );
  }

  // Formateo simple; sustituir por intl si se requiere localización
  String formatCurrency(double v) => '${v.toStringAsFixed(2)} EUR';

  // Selector de periodo discreto con SegmentedButton + icono de calendario
  Widget buildPeriodChips({
    required DateTimeRange initial,
    required ValueChanged<DateTimeRange> onChanged,
  }) {
    final now = DateTime.now();
    final monthRange = _monthRange(now);
    final quarterRange = _quarterRange(now);
    final yearRange = _yearRange(now.year);

    final isQuarter = _equals(initial, quarterRange);
    final isYear = _equals(initial, yearRange);

    int selected = 0;
    if (isQuarter) {
      selected = 1;
    } else if (isYear) {
      selected = 2;
    } else {
      selected = 0;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Mes')),
              ButtonSegment(value: 1, label: Text('Trimestre')),
              ButtonSegment(value: 2, label: Text('Año')),
            ],
            showSelectedIcon: false,
            selected: {selected},
            style: ButtonStyle(
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              textStyle: WidgetStatePropertyAll(
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            onSelectionChanged: (sel) {
              final v = sel.first;
              if (v == 0) {
                onChanged(monthRange);
              }
              if (v == 1) {
                onChanged(quarterRange);
              }
              if (v == 2) {
                onChanged(yearRange);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Rango personalizado',
          icon: const Icon(Icons.calendar_month, size: 20),
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2010),
              lastDate: DateTime(now.year + 1, 12, 31),
              initialDateRange: initial,
            );
            if (!context.mounted) return;
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }

  // Gráfica de barras mensual ingresos/gastos
  Widget buildMonthlyBarChart({
    required List<String> labels,
    required List<double> income,
    required List<double> expenses,
  }) {
    if (labels.isEmpty) return const SizedBox.shrink();
    // Ajuste dinámico de visibilidad de etiquetas
    final len = labels.length;
    final step = len > 10 ? 3 : (len > 6 ? 2 : 1);
    final rodWidth = len >= 10 ? 5.0 : 7.0;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _niceInterval(maxY(income, expenses)),
            getDrawingHorizontalLine:
                (value) => FlLine(color: Colors.black12, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length || i % step != 0) {
                    return const SizedBox.shrink();
                  }
                  final child = Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Transform.rotate(
                      angle: -0.6,
                      child: Text(
                        labels[i],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  );
                  return SideTitleWidget(meta: meta, child: child);
                },
              ),
            ),
          ),
          barGroups: List.generate(labels.length, (i) {
            return BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: income[i],
                  color: Colors.teal,
                  width: rodWidth,
                  borderRadius: BorderRadius.zero,
                ),
                BarChartRodData(
                  toY: expenses[i],
                  color: Colors.deepOrange,
                  width: rodWidth,
                  borderRadius: BorderRadius.zero,
                ),
              ],
            );
          }),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              top: BorderSide(color: Colors.transparent),
              right: BorderSide(color: Colors.transparent),
              left: BorderSide(color: Colors.black12),
              bottom: BorderSide(color: Colors.black12),
            ),
          ),
        ),
      ),
    );
  }

  // Gráfica lineal mensual ingresos/gastos con posible overlay YoY
  Widget buildMonthlyLineChartWithYoY({
    required List<String> labels,
    required List<double> income,
    required List<double> expenses,
    List<double>? yoyIncome,
    List<double>? yoyExpenses,
    bool showYoY = false,
    DateTimeRange? range,
    bool cutAtToday = false,
    VoidCallback? onToggleCutAtToday,
  }) {
    if (labels.isEmpty) return const SizedBox.shrink();

    final hasYoY = showYoY && yoyIncome != null && yoyExpenses != null;
    double maxVal = maxY(income, expenses);
    if (hasYoY) {
      final maxYoy = maxY(yoyIncome, yoyExpenses);
      if (maxYoy > maxVal) maxVal = maxYoy;
    }

    final incomeSpots = List.generate(
      labels.length,
      (i) => FlSpot(i.toDouble(), i < income.length ? income[i] : 0),
    );
    final expensesSpots = List.generate(
      labels.length,
      (i) => FlSpot(i.toDouble(), i < expenses.length ? expenses[i] : 0),
    );
    final yoyIncomeSpots =
        hasYoY
            ? List.generate(
              labels.length,
              (i) => FlSpot(
                i.toDouble(),
                i < (yoyIncome.length) ? (yoyIncome[i]) : 0,
              ),
            )
            : const <FlSpot>[];
    final yoyExpensesSpots =
        hasYoY
            ? List.generate(
              labels.length,
              (i) => FlSpot(
                i.toDouble(),
                i < (yoyExpenses.length) ? (yoyExpenses[i]) : 0,
              ),
            )
            : const <FlSpot>[];

    final len = labels.length;
    final step = len > 10 ? 3 : (len > 6 ? 2 : 1);

    final minX = 0.0;
    double maxX = labels.length == 1 ? 1.0 : (labels.length - 1).toDouble();
    if (cutAtToday && range != null) {
      final now = DateTime.now();
      final sameMonth =
          range.start.year == now.year &&
          range.end.year == now.year &&
          range.start.month == now.month &&
          range.end.month == now.month;
      if (sameMonth) {
        final todayIdx = now.day - 1;
        if (todayIdx >= 0 && todayIdx < labels.length) {
          maxX = todayIdx.toDouble();
        }
      }
    }
    final yy = DateTime.now().year % 100;
    final yyPrev = (yy - 1) % 100;

    final legend = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _legendDot(
                  color: Colors.teal,
                  label: "Ingresos '${yy.toString().padLeft(2, '0')}",
                ),
                _legendDot(
                  color: Colors.deepOrange,
                  label: "Gastos '${yy.toString().padLeft(2, '0')}",
                ),
                if (hasYoY)
                  _legendDot(
                    color: Colors.teal.withAlpha(160),
                    label: "Ingresos '${yyPrev.toString().padLeft(2, '0')}",
                  ),
                if (hasYoY)
                  _legendDot(
                    color: Colors.deepOrange.withAlpha(160),
                    label: "Gastos '${yyPrev.toString().padLeft(2, '0')}",
                  ),
              ],
            ),
          ),
          if (range != null &&
              range.start.year == range.end.year &&
              range.start.month == range.end.month &&
              onToggleCutAtToday != null)
            TextButton.icon(
              onPressed: onToggleCutAtToday,
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.timeline, size: 14),
              label: Text(cutAtToday ? 'Hasta hoy' : 'Mes completo'),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        legend,
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: 0,
              maxY: maxVal == 0 ? 1 : maxVal * 1.1,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _niceInterval(maxVal),
                getDrawingHorizontalLine:
                    (value) =>
                        const FlLine(color: Colors.black12, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      final v = value.toInt();
                      return Text(
                        v == 0 ? '0' : '$v',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 ||
                          i >= labels.length ||
                          i % step != 0 ||
                          i.toDouble() > maxX) {
                        return const SizedBox.shrink();
                      }
                      String text;
                      final useDaily =
                          range != null &&
                          range.start.year == range.end.year &&
                          range.start.month == range.end.month &&
                          labels.length >= 20; // heurística: diario
                      if (useDaily) {
                        final base = DateTime(
                          range.start.year,
                          range.start.month,
                          1,
                        );
                        final date = base.add(Duration(days: i));
                        text = '${date.day} ${_mesAbreviado(date.month)}';
                      } else {
                        text = labels[i];
                      }
                      final child = Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Transform.rotate(
                          angle: -0.6,
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      );
                      return SideTitleWidget(meta: meta, child: child);
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  top: BorderSide(color: Colors.transparent),
                  right: BorderSide(color: Colors.transparent),
                  left: BorderSide(color: Colors.black12),
                  bottom: BorderSide(color: Colors.black12),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchSpotThreshold: 16,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBorderRadius: BorderRadius.circular(10),
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  maxContentWidth: 260,
                  fitInsideHorizontally: true,
                  getTooltipItems: (touchedSpots) {
                    final yy = DateTime.now().year % 100;
                    final yyPrev = (yy - 1) % 100;
                    return touchedSpots.map((s) {
                      final c = s.bar.color ?? Colors.teal;
                      String name;
                      if (c == Colors.teal) {
                        name = "Ingresos '${yy.toString().padLeft(2, '0')}";
                      } else if (c == Colors.deepOrange) {
                        name = "Gastos '${yy.toString().padLeft(2, '0')}";
                      } else if (c == Colors.teal.withAlpha(160)) {
                        name =
                            "Ingresos '${yyPrev.toString().padLeft(2, '0')}'";
                      } else if (c == Colors.deepOrange.withAlpha(160)) {
                        name = "Gastos '${yyPrev.toString().padLeft(2, '0')}";
                      } else {
                        name = '';
                      }
                      return LineTooltipItem(
                        '$name: ',
                        TextStyle(
                          color: c,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '${s.y.toStringAsFixed(2)} EUR',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
                getTouchedSpotIndicator: (barData, indexes) {
                  return indexes
                      .map(
                        (i) => TouchedSpotIndicatorData(
                          FlLine(color: Colors.black26, strokeWidth: 1),
                          FlDotData(
                            show: true,
                            getDotPainter:
                                (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                                      radius: 4,
                                      color: bar.color ?? Colors.teal,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    ),
                          ),
                        ),
                      )
                      .toList();
                },
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  color: Colors.teal,
                  barWidth: 3.5,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.teal.withAlpha(24),
                  ),
                ),
                LineChartBarData(
                  spots: expensesSpots,
                  isCurved: true,
                  color: Colors.deepOrange,
                  barWidth: 3.5,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.deepOrange.withAlpha(18),
                  ),
                ),
                if (hasYoY)
                  LineChartBarData(
                    spots: yoyIncomeSpots,
                    isCurved: true,
                    color: Colors.teal.withAlpha(160),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                if (hasYoY)
                  LineChartBarData(
                    spots: yoyExpensesSpots,
                    isCurved: true,
                    color: Colors.deepOrange.withAlpha(160),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot({required Color color, required String label}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );

  // Gráfica mini overlay para YoY (sin ejes/leyendas)
  Widget buildMonthlyLineChartOverlay({
    required List<String> labels,
    required List<double> income,
    required List<double> expenses,
  }) {
    double maxVal = maxY(income, expenses);
    final incomeSpots = List.generate(
      labels.length,
      (i) => FlSpot(i.toDouble(), i < income.length ? income[i] : 0),
    );
    final expensesSpots = List.generate(
      labels.length,
      (i) => FlSpot(i.toDouble(), i < expenses.length ? expenses[i] : 0),
    );

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (labels.length - 1).toDouble(),
          minY: 0,
          maxY: maxVal == 0 ? 1 : maxVal * 1.1,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: Colors.teal.withAlpha(180),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: expensesSpots,
              isCurved: true,
              color: Colors.deepOrange.withAlpha(180),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  // Menú compacto para cambiar el periodo (mes/trimestre/año/personalizado)
  Widget buildPeriodMenu({
    required DateTimeRange initial,
    required ValueChanged<DateTimeRange> onChanged,
  }) {
    return PopupMenuButton<_PeriodAction>(
      tooltip: 'Periodo',
      position: PopupMenuPosition.under,
      icon: const Icon(Icons.tune, size: 20),
      itemBuilder:
          (context) => const [
            PopupMenuItem(
              value: _PeriodAction.month,
              child: Text('Mes actual'),
            ),
            PopupMenuItem(
              value: _PeriodAction.quarter,
              child: Text('Trimestre actual'),
            ),
            PopupMenuItem(value: _PeriodAction.year, child: Text('Año actual')),
            PopupMenuDivider(),
            PopupMenuItem(
              value: _PeriodAction.custom,
              child: Text('Personalizado...'),
            ),
          ],
      onSelected: (value) async {
        final now = DateTime.now();
        switch (value) {
          case _PeriodAction.month:
            onChanged(_monthRange(now));
            break;
          case _PeriodAction.quarter:
            onChanged(_quarterRange(now));
            break;
          case _PeriodAction.year:
            onChanged(_yearRange(now.year));
            break;
          case _PeriodAction.custom:
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2010),
              lastDate: DateTime(now.year + 1, 12, 31),
              initialDateRange: initial,
            );
            if (!context.mounted) return;
            if (picked != null) onChanged(picked);
            break;
        }
      },
    );
  }

  // Utilidad para calcular una malla amigable
  double _niceInterval(double max) {
    if (max <= 0) return 50;
    final raw = max / 4.0;
    final pow10 = (math.log(raw) / math.ln10).floor();
    final base = math.pow(10, pow10).toDouble();
    for (final m in [1, 2, 5, 10]) {
      final v = m * base;
      if (v >= raw) return v.toDouble();
    }
    return base * 10.0;
  }

  double maxY(List<double> a, List<double> b) {
    final maxA = a.isEmpty ? 0.0 : a.reduce((x, y) => x > y ? x : y);
    final maxB = b.isEmpty ? 0.0 : b.reduce((x, y) => x > y ? x : y);
    return maxA > maxB ? maxA : maxB;
  }

  // Helpers privados de rango
  String _mesAbreviado(int m) =>
      const [
        '',
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
      ][m];

  bool _equals(DateTimeRange a, DateTimeRange b) =>
      a.start.isAtSameMomentAs(b.start) && a.end.isAtSameMomentAs(b.end);

  DateTimeRange _monthRange(DateTime d) {
    final start = DateTime(d.year, d.month, 1);
    final end = DateTime(d.year, d.month + 1, 0, 23, 59, 59, 999);
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _quarterRange(DateTime d) {
    final q = ((d.month - 1) ~/ 3) + 1;
    final startMonth = (q - 1) * 3 + 1;
    final start = DateTime(d.year, startMonth, 1);
    final end = DateTime(d.year, startMonth + 3, 0, 23, 59, 59, 999);
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _yearRange(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 0, 23, 59, 59, 999);
    return DateTimeRange(start: start, end: end);
  }
}

enum _PeriodAction { month, quarter, year, custom }
