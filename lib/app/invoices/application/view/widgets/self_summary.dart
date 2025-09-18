import 'package:flutter/material.dart';
import 'package:gestr/app/invoices/application/viewmodel/create_invoice_viewmodel.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';

class SelfSummaryCard extends StatelessWidget {
  const SelfSummaryCard({
    super.key,
    required this.user,
    required this.direction,
    required this.theme,
  });

  final SelfEmployedUser user;
  final InvoiceDirection direction;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final roleLabel = direction == InvoiceDirection.issued ? 'Emisor' : 'Receptor';
    final background = theme.colorScheme.secondary.withValues(alpha: 0.08);
    final borderColor = theme.colorScheme.secondary.withValues(alpha: 0.2);
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis datos ($roleLabel)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text('Nombre: ${user.fullName}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('NIF: ${user.dni}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('Direccion: ${user.address}', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class SelfSummarySkeleton extends StatelessWidget {
  const SelfSummarySkeleton({super.key, required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final bg = theme.colorScheme.secondary.withValues(alpha: 0.08);
    final border = theme.colorScheme.secondary.withValues(alpha: 0.2);
    final line = theme.colorScheme.onSurface.withValues(alpha: 0.2);
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 14, width: 120, color: line),
          const SizedBox(height: 8),
          Container(height: 12, width: 220, color: line),
          const SizedBox(height: 6),
          Container(height: 12, width: 160, color: line),
          const SizedBox(height: 6),
          Container(height: 12, width: 260, color: line),
        ],
      ),
    );
  }
}

