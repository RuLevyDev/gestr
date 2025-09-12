import 'package:flutter/material.dart';

abstract class OrderItemVm {
  TextEditingController get productController;
  TextEditingController get quantityController;
  TextEditingController get priceController;
  bool get persisted;
}

class OrderItemsEditor extends StatelessWidget {
  final List<OrderItemVm> items;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onChanged;
  final double total;
  final VoidCallback onSave;
  final bool canSave;
  final bool showAddButton;

  const OrderItemsEditor({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    required this.total,
    required this.onSave,
    required this.canSave,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++)
          _ItemRow(
            productController: items[i].productController,
            quantityController: items[i].quantityController,
            priceController: items[i].priceController,
            onRemove: () => onRemove(i),
            onChanged: onChanged,
          ),
        const SizedBox(height: 8),
        if (showAddButton)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Añadir pedido o producto'),
            ),
          ),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Total: EUR ${total.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSave ? onSave : null,
                    style: ElevatedButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.titleSmall,
                    ),
                    child: const Text('Guardar pedido o producto'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final TextEditingController productController;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ItemRow({
    required this.productController,
    required this.quantityController,
    required this.priceController,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: productController,
              decoration: const InputDecoration(labelText: 'Producto'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Cant.'),
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
        ],
      ),
    );
  }
}
