import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_event.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(invoice.status, context);
    final totalAmount = invoice.netAmount + invoice.iva;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Slidable(
          key: ValueKey(invoice.id),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.4,
            children: [
              SlidableAction(
                onPressed: (context) async {
                  if (invoice.image != null) {
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(invoice.image!.path)],
                        text: 'Factura: ${invoice.title}',
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No hay imagen para compartir'),
                      ),
                    );
                  }
                },
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.blueAccent,
                icon: Icons.share,
              ),
              SlidableAction(
                onPressed: (context) {
                  if (onDelete != null) onDelete!();
                  context.read<InvoiceBloc>().add(
                    InvoiceEvent.delete(invoice.id!),
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
              color:
                  !isDark
                      ? Colors.teal.withValues(alpha: 0.18)
                      : Colors.deepPurple.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                invoice.image != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        invoice.image!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Icon(
                      Icons.description,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          // color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().format(invoice.date),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${totalAmount.toStringAsFixed(2)} €",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        invoice.status.labelEs.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status, BuildContext context) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.greenAccent;
      case InvoiceStatus.sent:
        return Colors.blueAccent;
      case InvoiceStatus.pending:
        return Colors.orangeAccent;
      case InvoiceStatus.overdue:
        return Colors.redAccent;
    }
  }
}
