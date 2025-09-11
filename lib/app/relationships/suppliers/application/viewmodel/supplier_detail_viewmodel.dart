import "dart:async";
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_event.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_state.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/order_items_editor.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:gestr/domain/entities/supplier_order.dart';
import 'package:gestr/domain/entities/supplier_order_item.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';

class OrderItemModel implements OrderItemVm {
  @override
  final TextEditingController productController = TextEditingController();
  @override
  final TextEditingController priceController = TextEditingController();
  @override
  final TextEditingController quantityController = TextEditingController(text: '1');
  bool persisted;
  OrderItemModel({this.persisted = false});

  double get unitPrice => double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
  int get quantity => int.tryParse(quantityController.text) ?? 1;
  double get totalPrice => unitPrice * quantity;

  void dispose() {
    productController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }
}

mixin SupplierDetailViewModel<T extends StatefulWidget> on State<T> {
  Supplier get supplier;

  final List<OrderItemModel> items = [];
  final List<SupplierOrder> orders = [];
  StreamSubscription<SupplierState>? _subscription;

  double get total => items.fold(0, (sum, it) => sum + it.totalPrice);

  void initSupplierVm(BuildContext context) {
    final id = supplier.id;
    if (id == null) return;
    final bloc = context.read<SupplierBloc>();
    _subscription = bloc.stream.listen((state) {
      if (!mounted) return;
      if (state is SupplierLoaded && state.suppliers.isNotEmpty) {
        final s = state.suppliers.first;
        items.clear();
        for (final it in s.orderItems) {
          final oi = OrderItemModel(persisted: true);
          oi.productController.text = it.product;
          oi.priceController.text = it.price.toStringAsFixed(2);
          oi.quantityController.text = it.quantity.toString();
          items.add(oi);
        }
        orders
          ..clear()
          ..addAll(s.orders);
        setState(() {});
      }
    });
    bloc.add(SupplierEvent.getById(id));
  }

  void disposeSupplierVm() {
    persistOrder(context);
    _subscription?.cancel();
    for (final it in items) {
      it.dispose();
    }
  }

  void addItem() {
    if (items.isNotEmpty) {
      final last = items.last;
      final hasName = last.productController.text.trim().isNotEmpty;
      final hasPrice = last.unitPrice > 0;
      if (!hasName || !hasPrice) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Completa producto y precio antes de añadir otra línea')),
          );
        }
        return;
      }
    }
    setState(() => items.add(OrderItemModel()));
  }

  Future<void> handleRemoveItem(int index) async {
    final item = items[index];
    if (item.persisted) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Eliminar producto'),
              content: const Text('¿Desea eliminar este producto del pedido?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
              ],
            ),
          ) ??
          false;
      if (!confirmed || !mounted) return;
      removeItemAt(index);
      persistOrder(context);
    } else {
      removeItemAt(index);
    }
  }

  void removeItemAt(int index) {
    setState(() {
      items[index].dispose();
      items.removeAt(index);
    });
  }

  void persistOrder(BuildContext ctx) {
    final id = supplier.id;
    if (id == null) return;
    final updated = Supplier(
      id: id,
      name: supplier.name,
      email: supplier.email,
      phone: supplier.phone,
      taxId: supplier.taxId,
      fiscalAddress: supplier.fiscalAddress,
      orderItems: items
          .map((e) => SupplierOrderItem(
                product: e.productController.text,
                price: e.unitPrice,
                quantity: e.quantity,
              ))
          .toList(),
      orders: orders,
    );
    ctx.read<SupplierBloc>().add(SupplierEvent.update(updated));
    for (final it in items) {
      it.persisted = true;
    }
  }

  bool get canSaveCurrentOrder {
    if (items.isEmpty) return false;
    for (final it in items) {
      final hasName = it.productController.text.trim().isNotEmpty;
      final hasPrice = it.unitPrice > 0;
      if (!hasName || !hasPrice) return false;
    }
    return true;
  }

  Future<void> saveOrder(BuildContext ctx) async {
    if (items.isEmpty) return;
    final savedItems = items
        .map((e) => SupplierOrderItem(
              product: e.productController.text,
              price: e.unitPrice,
              quantity: e.quantity,
            ))
        .toList();
    final orderTotal = savedItems.fold<double>(0, (s, it) => s + it.price * it.quantity);
    final description = savedItems
        .map((e) => '${e.product} x${e.quantity} (${e.price.toStringAsFixed(2)})')
        .join(', ');

    final addToFixed = await showDialog<bool>(
          context: ctx,
          builder: (dialog) => AlertDialog(
            title: const Text('Guardar pedido'),
            content: const Text('¿Quieres añadir este pedido a Pagos fijos?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: const Text('No')),
              FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: const Text('Sí')),
            ],
          ),
        ) ??
        false;

    if (addToFixed) {
      final date = await showDatePicker(
        context: ctx,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (!mounted) return;
      if (date != null) {
        final payment = FixedPayment(
          title: 'Pedido ${supplier.name}',
          amount: orderTotal,
          startDate: date,
          frequency: FixedPaymentFrequency.monthly,
          description: description.isEmpty ? null : description,
          supplier: supplier.name,
        );
        ctx.read<FixedPaymentBloc>().add(FixedPaymentEvent.create(payment));
        if (!mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Añadido a pagos fijos')),
        );
      }
    }

    final isSingle = savedItems.length == 1;
    final nextIndex = orders.length + 1;
    final defaultTitle = isSingle ? 'Producto $nextIndex' : 'Pedido $nextIndex';
    orders.add(SupplierOrder(date: DateTime.now(), items: savedItems, title: defaultTitle));

    setState(() {
      for (final it in items) {
        it.dispose();
      }
      items.clear();
    });

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
      ctx.read<SupplierBloc>().add(SupplierEvent.update(updated));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Pedido guardado')));
  }
}

