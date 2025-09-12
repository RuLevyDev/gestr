import 'package:flutter/material.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/order_items_editor.dart';
import 'package:gestr/app/relationships/suppliers/application/viewmodel/temp_order_item_vm.dart';
import 'package:gestr/domain/entities/supplier_order_item.dart';

class SupplierEditOrderSheet extends StatefulWidget {
  final List<SupplierOrderItem> initialItems;
  final void Function(List<SupplierOrderItem> items) onSave;

  const SupplierEditOrderSheet({
    super.key,
    required this.initialItems,
    required this.onSave,
  });

  @override
  State<SupplierEditOrderSheet> createState() => _SupplierEditOrderSheetState();
}

class _SupplierEditOrderSheetState extends State<SupplierEditOrderSheet> {
  late List<TempOrderItemVm> _vms;

  @override
  void initState() {
    super.initState();
    _vms = [
      for (final it in widget.initialItems)
        TempOrderItemVm(
          product: it.product,
          quantity: it.quantity,
          price: it.price,
        ),
    ];
  }

  @override
  void dispose() {
    for (final vm in _vms) {
      vm.dispose();
    }
    super.dispose();
  }

  double get _total {
    double s = 0;
    for (final vm in _vms) {
      final q = int.tryParse(vm.quantityController.text.trim()) ?? 0;
      final p =
          double.tryParse(
            vm.priceController.text.replaceAll(',', '.').trim(),
          ) ??
          0.0;
      s += q * p;
    }
    return s;
  }

  bool get _canSave {
    if (_vms.isEmpty) return false;
    for (final vm in _vms) {
      final nameOk = vm.productController.text.trim().isNotEmpty;
      final q = int.tryParse(vm.quantityController.text.trim()) ?? 0;
      final p =
          double.tryParse(
            vm.priceController.text.replaceAll(',', '.').trim(),
          ) ??
          0.0;
      if (!nameOk || q <= 0 || p <= 0) return false;
    }
    return true;
  }

  void _save() {
    if (!_canSave) return;
    final items = [
      for (final vm in _vms)
        SupplierOrderItem(
          product: vm.productController.text.trim(),
          quantity: int.tryParse(vm.quantityController.text.trim()) ?? 1,
          price:
              double.tryParse(
                vm.priceController.text.replaceAll(',', '.').trim(),
              ) ??
              0.0,
        ),
    ];
    widget.onSave(items);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Editar pedido', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          OrderItemsEditor(
            items: _vms,
            onAdd: () => setState(() => _vms.add(TempOrderItemVm())),
            onRemove:
                (i) => setState(() {
                  _vms[i].dispose();
                  _vms.removeAt(i);
                }),
            onChanged: () => setState(() {}),
            total: _total,
            onSave: _save,
            canSave: _canSave,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
