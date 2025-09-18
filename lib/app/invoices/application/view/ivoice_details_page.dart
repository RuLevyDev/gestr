import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_state.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:gestr/app/invoices/bloc/invoice_event.dart';

class InvoiceDetailPage extends StatefulWidget {
  final Invoice invoice;
  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  late Invoice invoice;

  @override
  void initState() {
    super.initState();
    invoice = widget.invoice;
  }

  List<InvoiceStatus> get _availableStatuses {
    switch (invoice.status) {
      case InvoiceStatus.sent:
        return const [InvoiceStatus.paid];
      case InvoiceStatus.pending:
        return const [InvoiceStatus.paidByMe];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: isDark ? const DialogBackground() : const BackgroundLight(),
        ),
        Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              'Detalle de factura',
              style: theme.textTheme.titleLarge,
            ),
            actions: [
              PopupMenuButton<InvoiceStatus>(
                tooltip: 'Cambiar estado',
                initialValue: invoice.status,
                enabled: _availableStatuses.isNotEmpty,
                onSelected: (status) {
                  final updated = invoice.copyWith(status: status);
                  setState(() => invoice = updated);
                  context.read<InvoiceBloc>().add(InvoiceEvent.update(updated));
                },
                itemBuilder:
                    (context) =>
                        _availableStatuses
                            .map(
                              (s) => PopupMenuItem(
                                value: s,
                                child: Text(s.labelEs),
                              ),
                            )
                            .toList(),
                child: _StatusChip(status: invoice.status),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: BlocBuilder<InvoiceBloc, InvoiceState>(
            builder: (context, state) {
              if (state is InvoiceLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is InvoiceError) {
                return Center(child: Text('Error: ${state.message}'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'FACTURA',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              letterSpacing: 3,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 6,
                                        children: [
                                          _kv('N.Ao', invoice.id ?? 'a', theme),
                                          _kv(
                                            'Fecha',
                                            _formatDate(invoice.date),
                                            theme,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: .12,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.black12),
                            const SizedBox(height: 16),

                            // Parties (Issuer / Receiver)
                            LayoutBuilder(
                              builder: (context, c) {
                                final isWide = c.maxWidth > 560;
                                final issuerLines = <String>[
                                  if (invoice.issuer != null &&
                                      invoice.issuer!.trim().isNotEmpty)
                                    invoice.issuer!.trim(),
                                  if (invoice.issuerTaxId != null &&
                                      invoice.issuerTaxId!.trim().isNotEmpty)
                                    'NIF: \${invoice.issuerTaxId}',
                                  if (invoice.issuerAddress != null &&
                                      invoice.issuerAddress!.trim().isNotEmpty)
                                    invoice.issuerAddress!.trim(),
                                ];
                                final receiverLines = <String>[
                                  if (invoice.receiver != null &&
                                      invoice.receiver!.trim().isNotEmpty)
                                    invoice.receiver!.trim(),
                                  if (invoice.receiverTaxId != null &&
                                      invoice.receiverTaxId!.trim().isNotEmpty)
                                    'NIF: \${invoice.receiverTaxId}',
                                  if (invoice.receiverAddress != null &&
                                      invoice.receiverAddress!
                                          .trim()
                                          .isNotEmpty)
                                    invoice.receiverAddress!.trim(),
                                ];
                                final children = <Widget>[
                                  if (issuerLines.isNotEmpty)
                                    _PartyBox(
                                      title: 'Emisor',
                                      value: issuerLines.join('\n'),
                                    ),
                                  if (receiverLines.isNotEmpty)
                                    _PartyBox(
                                      title: 'Receptor',
                                      value: receiverLines.join('\n'),
                                    ),
                                ];
                                if (!isWide) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [...children],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child:
                                          children.isNotEmpty
                                              ? children[0]
                                              : const SizedBox(),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child:
                                          children.length > 1
                                              ? children[1]
                                              : const SizedBox(),
                                    ),
                                  ],
                                );
                              },
                            ),

                            if (invoice.concept != null) ...[
                              const SizedBox(height: 20),
                              Text(
                                'Concepto',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: .25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SelectableText(
                                  invoice.concept!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: _TotalsTable(invoice: invoice),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Divider(color: Colors.black12),

                            if (invoice.imageUrl != null ||
                                invoice.image != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Adjuntos',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  if (invoice.imageUrl != null)
                                    _AttachmentCard.network(
                                      url: invoice.imageUrl!,
                                    ),
                                  if (invoice.image != null)
                                    _AttachmentCard.file(
                                      path: invoice.image!.path,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  // Small key/value for header
  Widget _kv(String k, String v, ThemeData theme) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        k,
        style: theme.textTheme.labelMedium?.copyWith(color: Colors.black54),
      ),
      const SizedBox(width: 6),
      SelectableText(v, style: theme.textTheme.bodyMedium),
    ],
  );
}

class _PartyBox extends StatelessWidget {
  final String title;
  final String value;
  const _PartyBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: .04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(value, style: theme.textTheme.bodyMedium),
          Divider(color: Colors.black12),
        ],
      ),
    );
  }
}

class _TotalsTable extends StatelessWidget {
  final Invoice invoice;
  const _TotalsTable({required this.invoice});

  String _money(double v) => '${v.toStringAsFixed(2)} EUR';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final rows = <_RowItem>[
      _RowItem('Base imponible', invoice.netAmount, false),
      _RowItem('IVA', invoice.iva, false),
      _RowItem('Total', invoice.total, true),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    i == rows.length - 1
                        ? theme.colorScheme.primary.withValues(alpha: .06)
                        : null,
                borderRadius:
                    i == 0
                        ? const BorderRadius.vertical(top: Radius.circular(12))
                        : i == rows.length - 1
                        ? const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        )
                        : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].label,
                    style:
                        rows[i].bold
                            ? text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )
                            : text.bodyMedium,
                  ),
                  Text(
                    _money(rows[i].value),
                    style:
                        rows[i].bold
                            ? text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )
                            : text.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RowItem {
  final String label;
  final double value;
  final bool bold;
  _RowItem(this.label, this.value, this.bold);
}

class _AttachmentCard extends StatelessWidget {
  final String? url;
  final String? path;
  const _AttachmentCard.network({required this.url}) : path = null;
  const _AttachmentCard.file({required this.path}) : url = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return SizedBox(
      width: 280,
      child: Card(
        elevation: 2,
        shape: border,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Stack(
            children: [
              if (url != null)
                Image.network(
                  url!,
                  fit: BoxFit.cover,
                  height: 180,
                  width: double.infinity,
                )
              else if (path != null)
                Image.file(
                  File(path!),
                  fit: BoxFit.cover,
                  height: 180,
                  width: double.infinity,
                ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: .75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    url != null ? 'Adjunto (red)' : 'Adjunto (local)',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color fg;
    switch (status) {
      case InvoiceStatus.paid:
        bg = Colors.green.withAlpha(32);
        fg = Colors.green.shade700;
        break;
      case InvoiceStatus.pending:
        bg = Colors.orange.withAlpha(32);
        fg = Colors.orange.shade800;
        break;
      case InvoiceStatus.sent:
        bg = Colors.blue.withAlpha(32);
        fg = Colors.blue.shade800;
        break;
      case InvoiceStatus.overdue:
        bg = Colors.red.withAlpha(32);
        fg = Colors.red.shade800;
        break;
      case InvoiceStatus.paidByMe:
        bg = Colors.purple.withAlpha(32);
        fg = Colors.purple.shade800;
        break;
    }
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.labelEs.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
