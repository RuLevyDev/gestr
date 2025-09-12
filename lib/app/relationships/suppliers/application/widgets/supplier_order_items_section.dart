import 'package:flutter/material.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/order_items_editor.dart';

class SupplierOrderItemsSection extends StatelessWidget {
  final List<OrderItemVm> items;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final VoidCallback onChanged;
  final double total;
  final VoidCallback onSave;
  final bool canSave;

  const SupplierOrderItemsSection({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    required this.total,
    required this.onSave,
    required this.canSave,
  });

  @override
  Widget build(BuildContext context) {
    return OrderItemsEditor(
      items: items,
      onAdd: onAdd,
      onRemove: onRemove,
      onChanged: onChanged,
      total: total,
      onSave: onSave,
      canSave: canSave,
    );
  }
}
