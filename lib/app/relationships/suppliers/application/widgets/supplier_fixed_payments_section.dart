import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/app/fixedpayments/application/widgets/fixed_payments_card.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/empty_message.dart';

class SupplierFixedPaymentsSection extends StatelessWidget {
  final String supplierName;
  const SupplierFixedPaymentsSection({super.key, required this.supplierName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FixedPaymentBloc, FixedPaymentState>(
      builder: (context, state) {
        if (state is FixedPaymentLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is FixedPaymentError) {
          return Text('Error al cargar pagos fijos: ${state.message}');
        }
        if (state is FixedPaymentLoaded) {
          final payments =
              state.fixedPayments
                  .where(
                    (p) =>
                        (p.supplier ?? '').toLowerCase() ==
                        supplierName.toLowerCase(),
                  )
                  .toList();
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.only(right: 12, left: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 245, 182, 67).withAlpha(48),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color.fromARGB(
                      255,
                      245,
                      182,
                      67,
                    ).withAlpha(80),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/create-fixed-payment',
                                arguments: {'supplier': supplierName},
                              ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 6,
                            ),
                            child: Text(
                              'Pagos fijos',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Añadir pago fijo',
                          onPressed:
                              () => Navigator.pushNamed(
                                context,
                                '/create-fixed-payment',
                                arguments: {'supplier': supplierName},
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (payments.isEmpty)
                      const EmptyMessage(
                        icon: Icons.payments_outlined,
                        message: 'No hay pagos fijos registrados.',
                      )
                    else
                      ...payments.map(
                        (p) => FixedPaymentCard(payment: p, onTap: () {}),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
