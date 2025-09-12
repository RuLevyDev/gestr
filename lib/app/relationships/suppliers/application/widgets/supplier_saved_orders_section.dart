import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/saved_orders_wrap.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/domain/entities/supplier_order.dart';

class SupplierSavedOrdersSection extends StatelessWidget {
  final List<SupplierOrder> orders;
  final String supplierName;
  final void Function(int index)? onTap;
  final VoidCallback? onAdd;

  const SupplierSavedOrdersSection({
    super.key,
    required this.orders,
    required this.supplierName,
    this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const SizedBox.shrink();
    return BlocBuilder<FixedPaymentBloc, FixedPaymentState>(
      builder: (context, state) {
        final payments = <FixedPayment>[];
        if (state is FixedPaymentLoaded) {
          payments.addAll(
            state.fixedPayments.where(
              (p) =>
                  (p.supplier ?? '').toLowerCase() ==
                  supplierName.toLowerCase(),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedidos guardados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (onAdd != null)
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 16,
                    ),
                    label: const Text('Añadir'),
                    style: Theme.of(context).textButtonTheme.style,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SavedOrdersWrap(orders: orders, payments: payments, onTap: onTap),
          ],
        );
      },
    );
  }
}
