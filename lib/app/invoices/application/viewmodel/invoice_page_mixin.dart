import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/invoices/application/view/invoices_page.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:table_calendar/table_calendar.dart';

mixin InvoicesPageMixin on State<InvoicesPage> {
  List<DateTime> generateNextOccurrences(FixedPayment payment, int count) {
    final List<DateTime> dates = [];
    DateTime nextDate = payment.startDate;

    while (dates.length < count) {
      if (nextDate.isAfter(DateTime.now())) {
        dates.add(nextDate);
      }

      switch (payment.frequency) {
        case FixedPaymentFrequency.weekly:
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case FixedPaymentFrequency.monthly:
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
          break;
        case FixedPaymentFrequency.quarterly:
          nextDate = DateTime(nextDate.year, nextDate.month + 3, nextDate.day);
          break;
        case FixedPaymentFrequency.fourMonthly:
          nextDate = DateTime(nextDate.year, nextDate.month + 4, nextDate.day);
          break;
        case FixedPaymentFrequency.semiYearly:
          nextDate = DateTime(nextDate.year, nextDate.month + 6, nextDate.day);
          break;
        case FixedPaymentFrequency.yearly:
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
          break;
        case FixedPaymentFrequency.custom:
          return dates;
      }
    }
    return dates;
  }

  List<MapEntry<FixedPayment, DateTime>> getUpcomingFixedPayments(
    List<FixedPayment> allPayments,
  ) {
    final now = DateTime.now();
    final List<MapEntry<FixedPayment, DateTime>> upcomingPayments = [];

    for (final payment in allPayments) {
      if (payment.frequency == FixedPaymentFrequency.custom) continue;

      // Solo obtener la próxima ocurrencia
      final nextDate = generateNextOccurrence(payment);
      if (nextDate.month == now.month && nextDate.year == now.year) {
        upcomingPayments.add(MapEntry(payment, nextDate));
      }
    }

    // Ordenar por fecha más próxima
    upcomingPayments.sort((a, b) => a.value.compareTo(b.value));
    return upcomingPayments;
  }

  DateTime generateNextOccurrence(FixedPayment payment) {
    final now = DateTime.now();
    DateTime nextDate = payment.startDate;

    while (!nextDate.isAfter(now)) {
      switch (payment.frequency) {
        case FixedPaymentFrequency.weekly:
          nextDate = nextDate.add(const Duration(days: 7));
          break;

        case FixedPaymentFrequency.monthly:
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
          break;

        case FixedPaymentFrequency.quarterly:
          nextDate = DateTime(nextDate.year, nextDate.month + 3, nextDate.day);
          break;

        case FixedPaymentFrequency.fourMonthly:
          nextDate = DateTime(nextDate.year, nextDate.month + 4, nextDate.day);
          break;

        case FixedPaymentFrequency.semiYearly:
          nextDate = DateTime(nextDate.year, nextDate.month + 6, nextDate.day);
          break;

        case FixedPaymentFrequency.yearly:
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
          break;

        case FixedPaymentFrequency.custom:
          final days = 1;
          nextDate = nextDate.add(Duration(days: days));
          break;
      }

      // Validar fechas inválidas como 31 en febrero, las ajustamos al último día del mes si falla
      if (!DateTime(nextDate.year, nextDate.month, 1)
          .add(Duration(days: nextDate.day - 1))
          .isBefore(DateTime(nextDate.year, nextDate.month + 1, 1))) {
        // Si el día no existe en ese mes, usar el último válido
        final lastDay = DateTime(nextDate.year, nextDate.month + 1, 0).day;
        nextDate = DateTime(nextDate.year, nextDate.month, lastDay);
      }
    }

    return nextDate;
  }

  Widget buildEmptyMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color color,
    bool showButton = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: color.withAlpha(180)),
              textAlign: TextAlign.center,
            ),
            if (showButton) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed:
                    () => Navigator.pushNamed(context, "/create-invoice"),
                icon: const Icon(Icons.add),
                label: const Text("Crear factura"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildEmptyFixedPaymentsMessage(bool isDark) {
    final color = isDark ? Colors.deepOrangeAccent : Colors.orange;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments_outlined, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              "No hay pagos fijos aún.",
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Agrega pagos recurrentes para un mejor control de tus gastos.",
              style: TextStyle(fontSize: 14, color: color.withAlpha(180)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  () => Navigator.pushNamed(context, "/create-fixed-payment"),
              icon: const Icon(Icons.add),
              label: const Text("Crear pago fijo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget buildFixedPaymentsCalendar(bool isDark) {
    return BlocBuilder<FixedPaymentBloc, FixedPaymentState>(
      builder: (context, state) {
        if (state is FixedPaymentLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FixedPaymentLoaded) {
          final payments = state.fixedPayments;
          final Map<DateTime, List<FixedPayment>> events = {};

          for (var payment in payments) {
            // Generamos próximas ocurrencias (por ejemplo, 12 meses hacia adelante)
            final occurrences = generateNextOccurrences(payment, 12);

            for (final date in occurrences) {
              final key = DateTime(date.year, date.month, date.day);
              events.putIfAbsent(key, () => []).add(payment);
            }
          }

          return TableCalendar<FixedPayment>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.twoWeeks,
            eventLoader:
                (day) => events[DateTime(day.year, day.month, day.day)] ?? [],
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: isDark ? Colors.deepOrangeAccent : Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: isDark ? Colors.deepOrange : Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: isDark ? Colors.deepOrange : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children:
                        events.take(1).map((payment) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: getFrequencyColor(
                                payment.frequency,
                                isDark,
                              ),
                            ),
                          );
                        }).toList(),
                  );
                }
                return null;
              },
            ),
          );
        } else if (state is FixedPaymentError) {
          return Center(child: Text("Error: ${state.message}"));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Color getFrequencyColor(FixedPaymentFrequency frequency, bool isDark) {
    switch (frequency) {
      case FixedPaymentFrequency.monthly:
        return isDark ? Colors.amberAccent : Colors.amber;
      case FixedPaymentFrequency.quarterly:
        return isDark ? Colors.cyanAccent : Colors.cyan;
      case FixedPaymentFrequency.fourMonthly:
        return isDark ? Colors.tealAccent : Colors.teal;
      case FixedPaymentFrequency.semiYearly:
        return isDark ? Colors.indigoAccent : Colors.indigo;
      case FixedPaymentFrequency.yearly:
        return isDark ? Colors.lightBlueAccent : Colors.lightBlue;
      case FixedPaymentFrequency.weekly:
        return isDark ? Colors.purpleAccent : Colors.purple;
      case FixedPaymentFrequency.custom:
        return isDark ? Colors.greenAccent : Colors.green;
    }
  }
}
