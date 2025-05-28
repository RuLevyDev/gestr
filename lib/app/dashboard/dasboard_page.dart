import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Map<String, dynamic>> financialStats = const [
    {
      'label': 'Ingresos',
      'value': 1200.0,
      'previous': 1000.0,
      'color': Colors.green,
    },
    {
      'label': 'Gastos',
      'value': 650.0,
      'previous': 500.0,
      'color': Colors.pinkAccent,
    },
    {
      'label': 'IVA',
      'value': 115.0,
      'previous': 110.0,
      'color': Colors.orangeAccent,
    },
    {
      'label': 'IRPF',
      'value': 95.0,
      'previous': 90.0,
      'color': Colors.deepPurpleAccent,
    },
  ];

  final List<FlSpot> ingresosData = [
    FlSpot(0, 1000),
    FlSpot(1, 1200),
    FlSpot(2, 900),
  ];
  final List<FlSpot> gastosData = [
    FlSpot(0, 500),
    FlSpot(1, 650),
    FlSpot(2, 400),
  ];
  final List<FlSpot> ivaData = [FlSpot(0, 100), FlSpot(1, 115), FlSpot(2, 90)];
  final List<FlSpot> irpfData = [FlSpot(0, 90), FlSpot(1, 95), FlSpot(2, 85)];

  final List<String> monthLabels = ['Ene', 'Feb', 'Mar'];

  bool showNet = false;
  bool showAvg = true;

  List<FlSpot> get ingresosNetosData {
    return List.generate(ingresosData.length, (i) {
      final neto =
          ingresosData[i].y - gastosData[i].y - ivaData[i].y - irpfData[i].y;
      return FlSpot(i.toDouble(), neto);
    });
  }

  double get promedioIngresosNetos {
    final data = ingresosNetosData.map((e) => e.y).toList();
    return data.reduce((a, b) => a + b) / data.length;
  }

  List<FlSpot> get avgData => List.generate(
    ingresosNetosData.length,
    (i) => FlSpot(i.toDouble(), promedioIngresosNetos),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 52),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  financialStats.map((item) {
                    return _buildGlassCard(
                      label: item['label'],
                      value: item['value'],
                      previous: item['previous'],
                      color: item['color'],
                    );
                  }).toList(),
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
                        showAvg = true; // reset promedio al cambiar modo
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

                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget:
                                  (value, _) => Text(
                                    value.toStringAsFixed(0),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                              reservedSize: 32,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                int index = value.toInt();
                                if (index >= 0 && index < monthLabels.length) {
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
                                  if (showAvg)
                                    LineChartBarData(
                                      spots: avgData,
                                      isCurved: false,
                                      color: const Color.fromARGB(
                                        255,
                                        214,
                                        7,
                                        255,
                                      ).withValues(alpha: 0.5),
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      dashArray: [5, 5],
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
                                      ? Colors.tealAccent.withValues(alpha: 0.8)
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
    // Defino las etiquetas que son "positivas" (incremento bueno)

    // La dirección real del cambio (sube o baja)
    final isIncrease = diff >= 0;

    // Evaluar si el cambio es positivo o negativo según el tipo
    final isPositiveChange =
        positiveLabels.contains(label)
            ? isIncrease // Para ingresos
            : !isIncrease; // Para gastos, IVA, IRPF: bajar es bueno

    final arrow = isIncrease ? Icons.arrow_upward : Icons.arrow_downward;
    final diffColor = isPositiveChange ? Colors.greenAccent : Colors.redAccent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
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
                  Text(
                    '${diff.abs().toStringAsFixed(0)} € mes anterior',
                    style: TextStyle(color: diffColor, fontSize: 11),
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
