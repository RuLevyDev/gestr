import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_state.dart';
import 'package:gestr/app/invoices/widgets/invoice_card.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/empty_message.dart';

class SupplierInvoicesSection extends StatelessWidget {
  final String supplierName;
  const SupplierInvoicesSection({super.key, required this.supplierName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceBloc, InvoiceState>(
      builder: (context, state) {
        if (state is InvoiceLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is InvoiceError) {
          return Text('Error al cargar facturas: ${state.message}');
        }
        if (state is InvoiceLoaded) {
          final invoices =
              state.invoices
                  .where(
                    (i) =>
                        (i.receiver ?? '').toLowerCase() ==
                        supplierName.toLowerCase(),
                  )
                  .toList();
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 29),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.tealAccent.withAlpha(25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facturas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (invoices.isEmpty)
                      const EmptyMessage(
                        icon: Icons.receipt_long_outlined,
                        message: 'No hay facturas relacionadas.',
                      )
                    else
                      ...invoices.map(
                        (inv) => InvoiceCard(invoice: inv, onTap: () {}),
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
