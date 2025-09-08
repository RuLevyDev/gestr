import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class FixedPaymentCard extends StatelessWidget {
  final FixedPayment payment;
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  const FixedPaymentCard({
    super.key,
    required this.payment,
    this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Slidable(
          key: ValueKey(payment.id),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.4,
            children: [
              if (payment.image != null)
                SlidableAction(
                  onPressed: (context) async {
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(payment.image!.path)],
                        text: 'Pago fijo: ${payment.title}',
                      ),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.blueAccent,
                  icon: Icons.share,
                ),
              SlidableAction(
                onPressed: (context) {
                  if (onDelete != null) onDelete!();
                  context.read<FixedPaymentBloc>().add(
                    FixedPaymentEvent.delete(payment.id!),
                  );
                },
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.redAccent,
                icon: Icons.delete_outline,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.indigo.withValues(alpha: 0.15)
                  : Colors.lightBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                payment.image != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        payment.image!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Icon(
                      Icons.attach_money,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().format(payment.startDate),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${payment.amount.toStringAsFixed(2)} €",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
