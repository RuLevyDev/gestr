import 'package:flutter/material.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
import 'package:gestr/domain/entities/supplier_order.dart';

import '../view/supplier_detail_types.dart';

class SupplierOrderDetailsDialog extends StatefulWidget {
  final SupplierOrder order;
  final String initialTitle;
  final Future<void> Function(String newTitle)? onSaveTitle;
  final Future<void> Function(BuildContext dialogCtx, String title)? onAddFixed;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onEdit;

  const SupplierOrderDetailsDialog({
    super.key,
    required this.order,
    required this.initialTitle,
    this.onSaveTitle,
    this.onAddFixed,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<SupplierOrderDetailsDialog> createState() =>
      _SupplierOrderDetailsDialogState();
}

class _SupplierOrderDetailsDialogState
    extends State<SupplierOrderDetailsDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final order = widget.order;
    final totalLocal = order.items.fold<double>(
      0,
      (s, it) => s + it.price * it.quantity,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final newTitle = _controller.text.trim();
        if (newTitle != widget.initialTitle && widget.onSaveTitle != null) {
          final save =
              await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Guardar cambios'),
                      content: const Text(
                        'Has cambiado el título. ¿Quieres guardar los cambios?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Sí'),
                        ),
                      ],
                    ),
              ) ??
              false;
          if (save) {
            await widget.onSaveTitle!(newTitle);
          }
        }
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    isDark ? const DialogBackground() : const BackgroundLight(),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: theme.textTheme.headlineSmall,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Título del pedido',
                            ),
                          ),
                        ),
                        PopupMenuButton<OrderDialogAction>(
                          onSelected: (action) async {
                            switch (action) {
                              case OrderDialogAction.addFixed:
                                if (widget.onAddFixed != null) {
                                  await widget.onAddFixed!(
                                    context,
                                    _controller.text.trim().isEmpty
                                        ? widget.initialTitle
                                        : _controller.text.trim(),
                                  );
                                }
                                break;
                              case OrderDialogAction.delete:
                                if (widget.onDelete != null) {
                                  await widget.onDelete!();
                                }
                                break;
                              case OrderDialogAction.edit:
                                if (widget.onEdit != null) {
                                  await widget.onEdit!();
                                }
                                break;
                              case OrderDialogAction.close:
                                break;
                            }
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: OrderDialogAction.addFixed,
                                  child: Text('Añadir a pagos fijos'),
                                ),
                                const PopupMenuItem(
                                  value: OrderDialogAction.delete,
                                  child: Text('Eliminar pedido'),
                                ),
                              ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    if (order.items.length == 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.items.first.quantity == 1
                                    ? order.items.first.product
                                    : '${order.items.first.quantity} x ${order.items.first.product}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              'EUR ${order.items.first.price.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: 240,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Producto')),
                              DataColumn(label: Text('Cant.')),
                              DataColumn(label: Text('Precio')),
                            ],
                            rows: [
                              for (final e in order.items)
                                DataRow(
                                  cells: [
                                    DataCell(Text(e.product)),
                                    DataCell(Text('${e.quantity}')),
                                    DataCell(
                                      Text('EUR ${e.price.toStringAsFixed(2)}'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Total: EUR ${totalLocal.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
