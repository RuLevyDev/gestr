import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/invoices/application/view/ivoice_details_page.dart';
import 'package:gestr/app/invoices/application/viewmodel/invoice_page_mixin.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_event.dart';
import 'package:gestr/app/invoices/bloc/invoice_state.dart';
import 'package:gestr/app/invoices/widgets/fixed_payments_card.dart';
import 'package:gestr/app/invoices/widgets/invoice_card.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> with InvoicesPageMixin {
  @override
  void initState() {
    super.initState();
    // Lanzar eventos para cargar datos al iniciar
    context.read<InvoiceBloc>().add(const InvoiceEvent.fetch());
    context.read<FixedPaymentBloc>().add(const FixedPaymentEvent.fetch());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42.0, horizontal: 24),
      child: BlocBuilder<FixedPaymentBloc, FixedPaymentState>(
        builder: (context, fixedPaymentState) {
          return BlocBuilder<InvoiceBloc, InvoiceState>(
            builder: (context, invoiceState) {
              // Loading
              if (fixedPaymentState is FixedPaymentLoading ||
                  invoiceState is InvoiceLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error en pagos fijos
              if (fixedPaymentState is FixedPaymentError) {
                return Center(
                  child: Text(
                    "Error pagos fijos: ${fixedPaymentState.message}",
                  ),
                );
              }

              // Error en facturas
              if (invoiceState is InvoiceError) {
                return Center(
                  child: Text("Error facturas: ${invoiceState.message}"),
                );
              }

              // Estados no cargados correctamente
              if (fixedPaymentState is! FixedPaymentLoaded ||
                  invoiceState is! InvoiceLoaded) {
                return const SizedBox.shrink();
              }

              final fixedPayments = fixedPaymentState.fixedPayments;
              final invoices = invoiceState.invoices;
              final upcomingPayments = getUpcomingFixedPayments(fixedPayments);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECCIÓN PAGOS FIJOS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pagos fijos',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (fixedPayments.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 28,
                            ),
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  "/create-fixed-payment",
                                ),
                            tooltip: "Crear pago fijo",
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(minHeight: 180),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color:
                            isDark
                                ? Colors.deepOrange.withAlpha(25)
                                : Colors.orange.withAlpha(25),
                      ),
                      child:
                          fixedPayments.isEmpty
                              ? buildEmptyFixedPaymentsMessage(isDark)
                              : Column(
                                children: [
                                  buildFixedPaymentsCalendar(isDark),
                                  ListView.builder(
                                    reverse: true,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(12),
                                    itemCount: upcomingPayments.length,
                                    itemBuilder: (context, index) {
                                      final entry = upcomingPayments[index];
                                      final payment = entry.key;
                                      // final date = entry.value;

                                      return FixedPaymentCard(
                                        payment: payment,
                                        onTap: () {},
                                        // subtitle: 'Próximo: ${DateFormat.yMMMMd().format(date)}',
                                      );
                                    },
                                  ),
                                ],
                              ),
                    ),

                    const SizedBox(height: 24),
                    // --- SECCIÓN FACTURAS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Facturas',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (invoices.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 28,
                            ),
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  "/create-invoice",
                                ),
                            tooltip: "Crear factura",
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: screenHeight * 0.3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color:
                            isDark
                                ? Colors.deepPurple.withAlpha(25)
                                : Colors.teal.withAlpha(25),
                      ),
                      child:
                          invoices.isEmpty
                              ? buildEmptyMessage(
                                icon: Icons.receipt_long_outlined,
                                title: "No hay facturas aún.",
                                subtitle:
                                    "Crea tu primera factura para comenzar a gestionar tus pagos.",
                                isDark: isDark,
                                color:
                                    isDark
                                        ? Colors.deepPurpleAccent
                                        : Colors.teal,
                                showButton: true,
                              )
                              : Scrollbar(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: invoices.length,
                                  itemBuilder: (context, index) {
                                    final invoice = invoices[index];
                                    return InvoiceCard(
                                      invoice: invoice,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => InvoiceDetailPage(
                                                  invoice: invoice,
                                                ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
