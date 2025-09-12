import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestr/app/dashboard/viewmodel/dashboard_page_mixin.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_state.dart';
import 'package:gestr/app/invoices/bloc/invoice_event.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with DashboardPageMixin {
  bool showNet = false;
  bool showAvg = true;

  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(const InvoiceEvent.fetch());
    context.read<FixedPaymentBloc>().add(const FixedPaymentEvent.fetch());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 52),
      child: SingleChildScrollView(
        child: BlocBuilder<FixedPaymentBloc, FixedPaymentState>(
          builder: (context, fixedState) {
            return BlocBuilder<InvoiceBloc, InvoiceState>(
              builder: (context, invState) {
                if (fixedState is FixedPaymentLoading ||
                    invState is InvoiceLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (fixedState is FixedPaymentError) {
                  return Center(
                    child: Text('Error pagos fijos: ${fixedState.message}'),
                  );
                }
                if (invState is InvoiceError) {
                  return Center(
                    child: Text('Error facturas: ${invState.message}'),
                  );
                }
                if (fixedState is! FixedPaymentLoaded ||
                    invState is! InvoiceLoaded) {
                  return const SizedBox.shrink();
                }

                final months = lastMonths(3);
                final monthLabels = months.map(monthLabel).toList();

                final netByMonth = sumInvoicesNetByMonth(
                  invState.invoices,
                  months,
                );
                final ivaByMonth = sumInvoicesIvaByMonth(
                  invState.invoices,
                  months,
                );
                final gastosByMonth = sumFixedPaymentsByMonth(
                  fixedState.fixedPayments,
                  months,
                );

                final ingresosData = List.generate(
                  months.length,
                  (i) => FlSpot(i.toDouble(), netByMonth[months[i]] ?? 0.0),
                );
                final gastosData = List.generate(
                  months.length,
                  (i) => FlSpot(i.toDouble(), gastosByMonth[months[i]] ?? 0.0),
                );
                final ivaData = List.generate(
                  months.length,
                  (i) => FlSpot(i.toDouble(), ivaByMonth[months[i]] ?? 0.0),
                );
                final irpfData = List<FlSpot>.generate(
                  months.length,
                  (i) => FlSpot(i.toDouble(), 0),
                );

                final ingresosNetosData = List.generate(months.length, (i) {
                  final neto =
                      ingresosData[i].y -
                      gastosData[i].y -
                      ivaData[i].y -
                      irpfData[i].y;
                  return FlSpot(i.toDouble(), neto);
                });
                final promedioIngresosNetos =
                    ingresosNetosData
                        .map((e) => e.y)
                        .fold<double>(0, (a, b) => a + b) /
                    (ingresosNetosData.isEmpty ? 1 : ingresosNetosData.length);

                final financialStats = [
                  {
                    'label': 'Ingresos',
                    'value': netByMonth[months[2]] ?? 0.0,
                    'previous': netByMonth[months[1]] ?? 0.0,
                    'color': Colors.green,
                  },
                  {
                    'label': 'Gastos',
                    'value': gastosByMonth[months[2]] ?? 0.0,
                    'previous': gastosByMonth[months[1]] ?? 0.0,
                    'color': Colors.pinkAccent,
                  },
                  {
                    'label': 'IVA',
                    'value': ivaByMonth[months[2]] ?? 0.0,
                    'previous': ivaByMonth[months[1]] ?? 0.0,
                    'color': Colors.orangeAccent,
                  },
                  {
                    'label': 'IRPF',
                    'value': 0.0,
                    'previous': 0.0,
                    'color': Colors.deepPurpleAccent,
                  },
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children:
                          financialStats
                              .map(
                                (item) => _buildGlassCard(
                                  label: item['label'] as String,
                                  value: (item['value'] as num).toDouble(),
                                  previous:
                                      (item['previous'] as num).toDouble(),
                                  color: item['color'] as Color,
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Evolución mensual',
                      style: theme.textTheme.headlineSmall!.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 33,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showNet = !showNet;
                                showAvg = true;
                              });
                            },
                            child: Text(
                              showNet ? 'Bruto' : 'Neto',
                              style: theme.textTheme.titleSmall!.copyWith(
                                color: theme.colorScheme.onTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AspectRatio(
                        aspectRatio: 1.6,
                        child: Stack(
                          children: [
                            LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                ),
                                extraLinesData:
                                    showNet && showAvg
                                        ? ExtraLinesData(
                                          horizontalLines: [
                                            HorizontalLine(
                                              y: promedioIngresosNetos,
                                              color: const Color.fromARGB(
                                                255,
                                                214,
                                                7,
                                                255,
                                              ).withValues(alpha: 0.5),
                                              strokeWidth: 2,
                                              dashArray: [6, 6],
                                            ),
                                          ],
                                        )
                                        : const ExtraLinesData(),
                                minX: 0,
                                maxX: (monthLabels.length - 1).toDouble(),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget:
                                          (value, _) => Text(
                                            value.toStringAsFixed(0),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                      reservedSize: 32,
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, _) {
                                        final index = value.toInt();
                                        if (index >= 0 &&
                                            index < monthLabels.length) {
                                          return Text(monthLabels[index]);
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                lineBarsData:
                                    showNet
                                        ? [
                                          LineChartBarData(
                                            spots: ingresosNetosData,
                                            isCurved: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.amber.shade400,
                                                Colors.amber.shade200,
                                              ],
                                            ),
                                            barWidth: 3,
                                            dotData: FlDotData(show: true),
                                          ),
                                        ]
                                        : [
                                          LineChartBarData(
                                            spots: ingresosData,
                                            isCurved: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.tealAccent.shade400,
                                                Colors.tealAccent.shade100,
                                              ],
                                            ),
                                            barWidth: 3,
                                            dotData: FlDotData(show: true),
                                          ),
                                          LineChartBarData(
                                            spots: gastosData,
                                            isCurved: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.pinkAccent.shade400,
                                                Colors.pinkAccent.shade100,
                                              ],
                                            ),
                                            barWidth: 3,
                                            dotData: FlDotData(show: false),
                                          ),
                                        ],
                              ),
                            ),
                            if (showNet)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() => showAvg = !showAvg);
                                  },
                                  child: Text(
                                    'avg',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isDark
                                              ? Colors.tealAccent.withValues(
                                                alpha: 0.8,
                                              )
                                              : Colors.purpleAccent.withValues(
                                                alpha: 0.8,
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String label,
    required double value,
    required double previous,
    required Color color,
  }) {
    final positiveLabels = ['Ingresos'];
    final diff = value - previous;
    final theme = Theme.of(context);
    final isIncrease = diff >= 0;
    final isPositiveChange =
        positiveLabels.contains(label) ? isIncrease : !isIncrease;
    final arrow = isIncrease ? Icons.arrow_upward : Icons.arrow_downward;
    final diffColor = isPositiveChange ? Colors.greenAccent : Colors.redAccent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                theme.brightness == Brightness.dark
                    ? Colors.purpleAccent.withValues(alpha: 0.08)
                    : Colors.lightBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.displaySmall!.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${value.toStringAsFixed(0)} €',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(arrow, size: 16, color: diffColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${diff.abs().toStringAsFixed(0)} € mes anterior',
                      style: TextStyle(color: diffColor, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
