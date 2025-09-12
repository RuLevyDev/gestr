import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/supplier_edit_order_sheet.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/supplier_order_details_dialog.dart';

import 'package:gestr/app/relationships/suppliers/bloc/supplier_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_event.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/order_items_editor.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:gestr/domain/entities/supplier_order.dart';
import 'package:gestr/domain/entities/supplier_order_item.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';

/// ViewModel mixin for SupplierDetailPage state.
/// Provides UI-facing item editors, saved orders, and helpers.
mixin SupplierDetailViewModel<T extends StatefulWidget> on State<T> {
  /// Must be provided by the State using this mixin.
  Supplier get supplier;

  /// Current editable items (for the order/product editor UI)
  final List<_OrderItemVmImpl> _itemVms = [];

  /// Saved orders for this supplier
  final List<SupplierOrder> orders = [];

  /// Expose item VMs to widgets via the interface
  List<OrderItemVm> get items => _itemVms;

  /// Initialize VM from current supplier
  void initSupplierVm(BuildContext context) {
    orders
      ..clear()
      ..addAll(supplier.orders);

    _itemVms.clear();
    if (supplier.orderItems.isNotEmpty) {
      for (final it in supplier.orderItems) {
        _itemVms.add(
          _OrderItemVmImpl(
            product: it.product,
            quantity: it.quantity,
            price: it.price,
            persisted: true,
          ),
        );
      }
    }
  }

  Future<void> showOrderDetailsDialog(int index) async {
    final order = orders[index];
    final isSingle = order.items.length == 1;
    final defaultLabel = isSingle ? 'Producto ' : 'Pedido ';
    final initialTitle = (order.title ?? defaultLabel).trim();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return SupplierOrderDetailsDialog(
          order: order,
          initialTitle: initialTitle,
          onSaveTitle: (newTitle) async {
            final updatedOrder = SupplierOrder(
              date: order.date,
              items: order.items,
              title: newTitle.isEmpty ? null : newTitle,
            );
            if (mounted) {
              setState(() => orders[index] = updatedOrder);
              final id = supplier.id;
              final updatedSupplier = Supplier(
                id: id,
                name: supplier.name,
                email: supplier.email,
                phone: supplier.phone,
                taxId: supplier.taxId,
                fiscalAddress: supplier.fiscalAddress,
                orderItems: const [],
                orders: orders,
              );
              context.read<SupplierBloc>().add(
                SupplierEvent.update(updatedSupplier),
              );
            }
          },
          onAddFixed: (ctx, title) => addOrderAsFixedPayment(ctx, order, title),
          onDelete: () async {
            final confirm =
                await showDialog<bool>(
                  context: dialogCtx,
                  builder:
                      (ctx2) => AlertDialog(
                        title: const Text('Eliminar pedido'),
                        content: const Text(
                          '¿Seguro que quieres eliminar este pedido?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx2).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx2).pop(true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                ) ??
                false;
            if (!mounted) return;
            if (confirm) {
              setState(() => orders.removeAt(index));
              final id = supplier.id;
              if (id != null) {
                final updated = Supplier(
                  id: id,
                  name: supplier.name,
                  email: supplier.email,
                  phone: supplier.phone,
                  taxId: supplier.taxId,
                  fiscalAddress: supplier.fiscalAddress,
                  orderItems: const [],
                  orders: orders,
                );
                context.read<SupplierBloc>().add(SupplierEvent.update(updated));
              }
              if (!dialogCtx.mounted) return;
              await deleteAssociatedFixedPayment(dialogCtx, order);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            }
          },
          onEdit: () async {
            if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            await openEditOrderSheet(index);
          },
        );
      },
    );
  }

  Future<void> openEditOrderSheet(int index) async {
    final original = orders[index];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SupplierEditOrderSheet(
          initialItems: original.items,
          onSave: (updatedItems) async {
            setState(() {
              orders[index] = SupplierOrder(
                date: original.date,
                items: updatedItems,
                title: original.title,
              );
            });
            final s = supplier;
            if (s.id != null && mounted) {
              final updated = Supplier(
                id: s.id,
                name: s.name,
                email: s.email,
                phone: s.phone,
                taxId: s.taxId,
                fiscalAddress: s.fiscalAddress,
                orderItems: const [],
                orders: orders,
              );
              context.read<SupplierBloc>().add(SupplierEvent.update(updated));
            }
            await updateAssociatedFixedPayment(ctx, original, updatedItems);
          },
        );
      },
    );
  }

  /// Dispose controllers
  void disposeSupplierVm() {
    for (final vm in _itemVms) {
      vm.dispose();
    }
    _itemVms.clear();
  }

  /// Add a blank item row
  void addItem() {
    setState(() {
      _itemVms.add(_OrderItemVmImpl());
    });
  }

  /// Remove item row at index
  void handleRemoveItem(int index) {
    if (index < 0 || index >= _itemVms.length) return;
    setState(() {
      _itemVms[index].dispose();
      _itemVms.removeAt(index);
    });
  }

  /// Sum of (price * quantity) for current editable items
  double get total {
    double sum = 0;
    for (final vm in _itemVms) {
      final q = int.tryParse(vm.quantityController.text.trim()) ?? 0;
      final p =
          double.tryParse(
            vm.priceController.text.replaceAll(',', '.').trim(),
          ) ??
          0.0;
      sum += (q * p);
    }
    return sum;
  }

  /// Whether we can save the current editable set as an order/product
  bool get canSaveCurrentOrder {
    if (_itemVms.isEmpty) return false;
    for (final vm in _itemVms) {
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

  /// Persist the current editable items as a saved order and clear the editor
  Future<void> saveOrder(BuildContext context) async {
    if (!canSaveCurrentOrder) return;

    final orderItems =
        _itemVms.map((vm) {
          final q = int.tryParse(vm.quantityController.text.trim()) ?? 1;
          final p =
              double.tryParse(
                vm.priceController.text.replaceAll(',', '.').trim(),
              ) ??
              0.0;
          return SupplierOrderItem(
            product: vm.productController.text.trim(),
            quantity: q,
            price: p,
          );
        }).toList();

    final newOrder = SupplierOrder(date: DateTime.now(), items: orderItems);

    setState(() {
      orders.add(newOrder);
      for (final vm in _itemVms) {
        vm.dispose();
      }
      _itemVms.clear();
    });

    // Ask if user wants to add this to Fixed Payments
    final totalLocal = orderItems.fold<double>(
      0,
      (s, it) => s + it.price * it.quantity,
    );
    final isSingle = orderItems.length == 1;
    final desc = orderItems
        .map(
          (e) =>
              '${e.quantity} x ${e.product} (${e.price.toStringAsFixed(2)} EUR)',
        )
        .join(', ');
    final addToFixed =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Añadir a pagos fijos'),
                content: Text(
                  isSingle
                      ? '¿Quieres añadir este producto como pago fijo?'
                      : '¿Quieres añadir este pedido como pago fijo?',
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
    if (addToFixed && context.mounted) {
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null && context.mounted) {
        final title = isSingle ? orderItems.first.product : 'Pedido';
        final payment = FixedPayment(
          title: title,
          amount: totalLocal,
          startDate: date,
          frequency: FixedPaymentFrequency.monthly,
          description: desc.isEmpty ? null : desc,
          supplier: supplier.name,
        );
        context.read<FixedPaymentBloc>().add(FixedPaymentEvent.create(payment));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Añadido a pagos fijos')));
      }
    }

    // Dispatch update to persist the new orders list; clear staged orderItems
    final s = supplier;
    if (s.id != null && context.mounted) {
      final updated = Supplier(
        id: s.id,
        name: s.name,
        email: s.email,
        phone: s.phone,
        taxId: s.taxId,
        fiscalAddress: s.fiscalAddress,
        orderItems: const [],
        orders: orders,
      );
      context.read<SupplierBloc>().add(SupplierEvent.update(updated));
    }
  }

  Future<void> addOrderAsFixedPayment(
    BuildContext dialogCtx,
    SupplierOrder order,
    String title,
  ) async {
    if (!mounted || !dialogCtx.mounted) return;
    final totalLocal = order.items.fold<double>(
      0,
      (s, it) => s + it.price * it.quantity,
    );
    final desc = order.items
        .map(
          (e) =>
              '${e.quantity} x ${e.product} (${e.price.toStringAsFixed(2)} EUR)',
        )
        .join(', ');
    final date = await showDatePicker(
      context: dialogCtx,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || !dialogCtx.mounted) return;
    if (date != null) {
      final payment = FixedPayment(
        title: title,
        amount: totalLocal,
        startDate: date,
        frequency: FixedPaymentFrequency.monthly,
        description: desc.isEmpty ? null : desc,
        supplier: supplier.name,
      );
      context.read<FixedPaymentBloc>().add(FixedPaymentEvent.create(payment));
      if (dialogCtx.mounted) {
        ScaffoldMessenger.of(
          dialogCtx,
        ).showSnackBar(const SnackBar(content: Text('Añadido a pagos fijos')));
      }
    }
  }

  Future<void> deleteAssociatedFixedPayment(
    BuildContext dialogCtx,
    SupplierOrder order,
  ) async {
    if (!mounted) return;
    final fpState = context.read<FixedPaymentBloc>().state;
    if (fpState is! FixedPaymentLoaded) return;
    final totalLocal = order.items.fold<double>(
      0,
      (s, it) => s + it.price * it.quantity,
    );
    final desc = order.items
        .map(
          (e) =>
              '${e.quantity} x ${e.product} (${e.price.toStringAsFixed(2)} EUR)',
        )
        .join(', ');
    FixedPayment? candidate;
    for (final p in fpState.fixedPayments) {
      final supplierMatch =
          (p.supplier ?? '').toLowerCase() == supplier.name.toLowerCase();
      final amountMatch = (p.amount - totalLocal).abs() < 0.01;
      final descMatch = (p.description ?? '') == desc;
      if (supplierMatch && amountMatch && descMatch) {
        candidate = p;
        break;
      }
    }
    if (candidate == null) {
      for (final p in fpState.fixedPayments) {
        final supplierMatch =
            (p.supplier ?? '').toLowerCase() == supplier.name.toLowerCase();
        final amountMatch = (p.amount - totalLocal).abs() < 0.01;
        if (supplierMatch && amountMatch) {
          candidate = p;
          break;
        }
      }
    }
    if (candidate != null && candidate.id != null) {
      context.read<FixedPaymentBloc>().add(
        FixedPaymentEvent.delete(candidate.id!),
      );
    }
  }

  Future<void> updateAssociatedFixedPayment(
    BuildContext sheetCtx,
    SupplierOrder original,
    List<SupplierOrderItem> updatedItems,
  ) async {
    if (!mounted || !sheetCtx.mounted) return;
    final oldTotal = original.items.fold<double>(
      0,
      (s, it) => s + it.price * it.quantity,
    );
    final newTotal = updatedItems.fold<double>(
      0,
      (s, it) => s + it.price * it.quantity,
    );
    final oldDesc = original.items
        .map(
          (e) =>
              '${e.quantity} x ${e.product} (${e.price.toStringAsFixed(2)} EUR)',
        )
        .join(', ');
    final newDesc = updatedItems
        .map(
          (e) =>
              '${e.quantity} x ${e.product} (${e.price.toStringAsFixed(2)} EUR)',
        )
        .join(', ');

    final fpState = context.read<FixedPaymentBloc>().state;
    if (fpState is! FixedPaymentLoaded) return;
    FixedPayment? candidate;
    for (final p in fpState.fixedPayments) {
      final supplierMatch =
          (p.supplier ?? '').toLowerCase() == supplier.name.toLowerCase();
      final amountMatch = (p.amount - oldTotal).abs() < 0.01;
      final descMatch = (p.description ?? '') == oldDesc;
      if (supplierMatch && amountMatch && descMatch) {
        candidate = p;
        break;
      }
    }
    if (candidate == null) {
      for (final p in fpState.fixedPayments) {
        final supplierMatch =
            (p.supplier ?? '').toLowerCase() == supplier.name.toLowerCase();
        final amountMatch = (p.amount - oldTotal).abs() < 0.01;
        if (supplierMatch && amountMatch) {
          candidate = p;
          break;
        }
      }
    }
    if (candidate != null && candidate.id != null) {
      final wantsUpdate =
          await showDialog<bool>(
            context: sheetCtx,
            builder:
                (dctx) => AlertDialog(
                  title: const Text('Actualizar pago fijo'),
                  content: const Text(
                    'Se ha detectado un pago fijo asociado. ¿Quieres actualizarlo con los nuevos importes y líneas?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dctx).pop(false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dctx).pop(true),
                      child: const Text('Sí'),
                    ),
                  ],
                ),
          ) ??
          false;
      if (!mounted || !sheetCtx.mounted) return;
      if (wantsUpdate) {
        DateTime? newDate = await showDatePicker(
          context: sheetCtx,
          initialDate: candidate.startDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (!mounted || !sheetCtx.mounted) return;
        newDate ??= candidate.startDate;
        final updatedPayment = FixedPayment(
          id: candidate.id,
          title: candidate.title,
          amount: newTotal,
          startDate: newDate,
          frequency: candidate.frequency,
          description: newDesc.isEmpty ? null : newDesc,
          supplier: candidate.supplier ?? supplier.name,
          vatRate: candidate.vatRate,
          amountIsGross: candidate.amountIsGross,
          deductible: candidate.deductible,
          category: candidate.category,
          image: candidate.image,
          imageUrl: candidate.imageUrl,
        );
        if (!mounted) return;
        context.read<FixedPaymentBloc>().add(
          FixedPaymentEvent.update(updatedPayment),
        );
      }
    }
  }
}

class _OrderItemVmImpl implements OrderItemVm {
  @override
  final TextEditingController productController;
  @override
  final TextEditingController quantityController;
  @override
  final TextEditingController priceController;
  @override
  final bool persisted;

  _OrderItemVmImpl({
    String product = '',
    int quantity = 1,
    double price = 0.0,
    this.persisted = false,
  }) : productController = TextEditingController(text: product),
       quantityController = TextEditingController(text: quantity.toString()),
       priceController = TextEditingController(
         text: price == 0.0 ? '' : price.toString(),
       );

  void dispose() {
    productController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}
