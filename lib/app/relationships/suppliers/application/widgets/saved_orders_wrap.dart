import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/domain/entities/supplier_order.dart';

class SavedOrdersWrap extends StatelessWidget {
  final List<SupplierOrder> orders;
  final List<FixedPayment> payments;
  final void Function(int index)? onTap;

  const SavedOrdersWrap({
    super.key,
    required this.orders,
    required this.payments,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(orders.length, (index) {
        final order = orders[index];
        final isSingle = order.items.length == 1;
        final defaultLabel = isSingle ? 'Producto ${index + 1}' : 'Pedido ${index + 1}';
        final label = (order.title?.trim().isNotEmpty == true) ? order.title! : defaultLabel;
        final total = order.items.fold<double>(0, (sum, it) => sum + (it.price * it.quantity));

        FixedPayment? matched;
        for (final p in payments) {
          if ((p.amount - total).abs() < 0.01) {
            matched = p;
            break;
          }
        }

        final text = StringBuffer()
          ..write('$label - Total: EUR ${total.toStringAsFixed(2)}');
        if (matched != null) {
          text.write(" - PF: ${DateFormat('d/M/yy').format(matched.startDate)}");
        }

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap == null ? null : () => onTap!(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              text.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      }),
    );
  }
}

