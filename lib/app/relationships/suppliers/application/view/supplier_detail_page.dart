import 'package:flutter/material.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_event.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_state.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:gestr/domain/entities/supplier_order_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_state.dart';
import 'package:gestr/app/invoices/widgets/fixed_payments_card.dart';
import 'package:gestr/app/invoices/widgets/invoice_card.dart';
import 'package:gestr/app/invoices/application/view/ivoice_details_page.dart';

import 'dart:async';

class SupplierDetailPage extends StatefulWidget {
  final Supplier supplier;
  final Future<void> Function() onEdit;
  final Future<bool> Function() onDelete;

  const SupplierDetailPage({
    super.key,
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage> {
  final List<_OrderItem> _items = [];
  StreamSubscription<SupplierState>? _subscription;

  double get _total => _items.fold(0, (sum, item) => sum + item.totalPrice);

  @override
  void initState() {
    super.initState();
    final id = widget.supplier.id;
    if (id != null) {
      final bloc = context.read<SupplierBloc>();
      _subscription = bloc.stream.listen((state) {
        if (state is SupplierLoaded && state.suppliers.isNotEmpty) {
          final supplier = state.suppliers.first;
          _items.clear();
          for (final it in supplier.orderItems) {
            final oi = _OrderItem(persisted: true);
            oi.productController.text = it.product;
            oi.priceController.text = it.price.toStringAsFixed(2);
            oi.quantityController.text = it.quantity.toString();
            _items.add(oi);
          }
          if (mounted) setState(() {});
        }
      });
      bloc.add(SupplierEvent.getById(id));
    }
  }

  void _addItem() {
    setState(() {
      _items.add(_OrderItem());
    });
  }

  Future<void> _handleRemoveItem(int index) async {
    final item = _items[index];
    if (item.persisted) {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Eliminar producto'),
                  content: const Text(
                    '¿Desea eliminar este producto del pedido?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
          ) ??
          false;
      if (!confirmed) return;
      _removeItemAt(index);
      _persistOrder();
    } else {
      _removeItemAt(index);
    }
  }

  void _removeItemAt(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  @override
  void dispose() {
    _persistOrder();
    _subscription?.cancel();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Widget _buildOrderItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Producto / Pedidos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < _items.length; i++)
          _ItemRow(
            item: _items[i],
            onRemove: () => _handleRemoveItem(i),
            onChanged: () => setState(() {}),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Añadir producto'),
          ),
        ),
        if (_items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Total: €${_total.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 33,
                        child: ElevatedButton(
                          onPressed: _saveAsFixedPayment,
                          child: const Text('Guardar pago fijo'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 33,
                        child: ElevatedButton(
                          onPressed: _saveOrder,
                          child: const Text('Guardar pedido'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _persistOrder() {
    final id = widget.supplier.id;
    if (id == null) return;
    final updated = Supplier(
      id: id,
      name: widget.supplier.name,
      email: widget.supplier.email,
      phone: widget.supplier.phone,
      taxId: widget.supplier.taxId,
      fiscalAddress: widget.supplier.fiscalAddress,
      orderItems:
          _items
              .map(
                (e) => SupplierOrderItem(
                  product: e.productController.text,
                  price: e.unitPrice,
                  quantity: e.quantity,
                ),
              )
              .toList(),
    );
    context.read<SupplierBloc>().add(SupplierEvent.update(updated));
    for (final item in _items) {
      item.persisted = true;
    }
  }

  void _saveOrder() {
    _persistOrder();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pedido guardado')));
    }
  }

  void _saveAsFixedPayment() {
    final description = _items
        .map(
          (e) =>
              '${e.productController.text} x${e.quantityController.text} (${e.priceController.text})',
        )
        .join(', ');
    final payment = FixedPayment(
      title: 'Pedido ${widget.supplier.name}',
      amount: _total,
      startDate: DateTime.now(),
      frequency: FixedPaymentFrequency.monthly,
      description: description.isEmpty ? null : description,
      supplier: widget.supplier.name,
    );
    context.read<FixedPaymentBloc>().add(FixedPaymentEvent.create(payment));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Añadido a pagos fijos')));
    }
  }

  Widget _buildFixedPaymentsSection() {
    return BlocBuilder<FixedPaymentBloc, FixedPaymentState>(
      builder: (context, state) {
        if (state is FixedPaymentLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is FixedPaymentError) {
          return Text('Error al cargar pagos fijos: \\${state.message}');
        }
        if (state is FixedPaymentLoaded) {
          final payments =
              state.fixedPayments
                  .where(
                    (p) =>
                        (p.supplier ?? '').toLowerCase() ==
                        widget.supplier.name.toLowerCase(),
                  )
                  .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pagos fijos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Añadir pago fijo',
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          '/create-fixed-payment',
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (payments.isEmpty)
                const _EmptyMessage(
                  icon: Icons.payments_outlined,
                  message: 'No hay pagos fijos registrados.',
                ),
              for (final p in payments)
                FixedPaymentCard(payment: p, onTap: () {}),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInvoicesSection() {
    return BlocBuilder<InvoiceBloc, InvoiceState>(
      builder: (context, state) {
        if (state is InvoiceLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is InvoiceError) {
          return Text('Error al cargar facturas: \\${state.message}');
        }
        if (state is InvoiceLoaded) {
          final invoices =
              state.invoices
                  .where(
                    (i) =>
                        (i.issuer ?? '').toLowerCase() ==
                        widget.supplier.name.toLowerCase(),
                  )
                  .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Facturas', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (invoices.isEmpty)
                const _EmptyMessage(
                  icon: Icons.receipt_long_outlined,
                  message: 'No hay facturas registradas.',
                ),
              for (final invoice in invoices)
                InvoiceCard(
                  invoice: invoice,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoiceDetailPage(invoice: invoice),
                      ),
                    );
                  },
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplier = widget.supplier;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: isDark ? const DialogBackground() : const BackgroundLight(),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              supplier.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            actions: [
              PopupMenuButton<_SupplierMenuOption>(
                onSelected: (option) async {
                  switch (option) {
                    case _SupplierMenuOption.edit:
                      await widget.onEdit();
                      break;
                    case _SupplierMenuOption.delete:
                      final deleted = await widget.onDelete();
                      if (deleted && context.mounted) {
                        Navigator.pop(context);
                      }
                      break;
                    case _SupplierMenuOption.call:
                      final phone = supplier.phone;
                      if (phone?.isNotEmpty == true) {
                        await launchUrl(Uri.parse('tel:$phone'));
                      }
                      break;
                    case _SupplierMenuOption.email:
                      final email = supplier.email;
                      if (email?.isNotEmpty == true) {
                        await launchUrl(Uri.parse('mailto:$email'));
                      }
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: _SupplierMenuOption.edit,
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: _SupplierMenuOption.delete,
                        child: Text('Eliminar'),
                      ),
                      if (supplier.phone?.isNotEmpty == true)
                        const PopupMenuItem(
                          value: _SupplierMenuOption.call,
                          child: Text('Llamar'),
                        ),
                      if (supplier.email?.isNotEmpty == true)
                        const PopupMenuItem(
                          value: _SupplierMenuOption.email,
                          child: Text('Enviar correo'),
                        ),
                    ],
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _InfoRow(
                  icon: Icons.email_outlined,
                  value:
                      supplier.email?.isNotEmpty == true
                          ? supplier.email!
                          : 'Correo no disponible',
                ),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  value:
                      supplier.phone?.isNotEmpty == true
                          ? supplier.phone!
                          : 'Teléfono no disponible',
                ),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  value:
                      supplier.taxId?.isNotEmpty == true
                          ? 'NIF: ${supplier.taxId}'
                          : 'NIF no disponible',
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  value:
                      supplier.fiscalAddress?.isNotEmpty == true
                          ? supplier.fiscalAddress!
                          : 'Dirección fiscal no disponible',
                ),
                const SizedBox(height: 16),
                _buildOrderItemsSection(),
                const SizedBox(height: 16),
                _buildFixedPaymentsSection(),
                const SizedBox(height: 16),
                _buildInvoicesSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final _OrderItem item;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ItemRow({
    required this.item,
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
              controller: item.productController,
              decoration: const InputDecoration(labelText: 'Producto'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextField(
              controller: item.quantityController,
              decoration: const InputDecoration(labelText: 'Cant.'),
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: item.priceController,
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

class _OrderItem {
  final TextEditingController productController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );
  bool persisted;

  _OrderItem({this.persisted = false});

  double get unitPrice =>
      double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
  int get quantity => int.tryParse(quantityController.text) ?? 1;

  double get totalPrice => unitPrice * quantity;

  void dispose() {
    productController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

enum _SupplierMenuOption { edit, delete, call, email }
