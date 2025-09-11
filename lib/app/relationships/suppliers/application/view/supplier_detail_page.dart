import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';

import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:gestr/domain/entities/supplier_order.dart';
import 'package:gestr/domain/entities/supplier_order_item.dart';

import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_state.dart';
import 'package:gestr/app/invoices/widgets/invoice_card.dart';
import 'package:gestr/app/invoices/widgets/fixed_payments_card.dart';
import 'package:gestr/app/invoices/application/view/ivoice_details_page.dart';

import 'package:gestr/app/relationships/suppliers/application/widgets/order_items_editor.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/saved_orders_wrap.dart';
import 'package:gestr/app/relationships/suppliers/application/viewmodel/supplier_detail_viewmodel.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_event.dart';

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

class _SupplierDetailPageState extends State<SupplierDetailPage>
    with SupplierDetailViewModel<SupplierDetailPage> {
  @override
  Supplier get supplier => widget.supplier;

  @override
  void initState() {
    super.initState();
    initSupplierVm(context);
  }

  @override
  void dispose() {
    disposeSupplierVm();
    super.dispose();
  }

  Widget _buildOrderItemsSection() {
    return OrderItemsEditor(
      items: items,
      onAdd: addItem,
      onRemove: (i) => handleRemoveItem(i),
      onChanged: () => setState(() {}),
      total: total,
      onSave: () => saveOrder(context),
      canSave: canSaveCurrentOrder,
    );
  }

  Widget _buildSavedOrdersSection() {
    if (orders.isEmpty) return const SizedBox.shrink();
    return BlocBuilder<FixedPaymentBloc, FixedPaymentState>(
      builder: (context, state) {
        final payments = <FixedPayment>[];
        if (state is FixedPaymentLoaded) {
          payments.addAll(
            state.fixedPayments.where(
              (p) => (p.supplier ?? '').toLowerCase() ==
                  widget.supplier.name.toLowerCase(),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedidos guardados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SavedOrdersWrap(
              orders: orders,
              payments: payments,
              onTap: (i) => _showOrderDetailsDialog(i),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showOrderDetailsDialog(int index) async {
    final order = orders[index];
    final isSingle = order.items.length == 1;
    final defaultLabel = isSingle ? 'Producto ${index + 1}' : 'Pedido ${index + 1}';
    final controller = TextEditingController(text: order.title ?? defaultLabel);

    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Dialog(
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
                              controller: controller,
                              style: theme.textTheme.headlineSmall,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Título del pedido',
                              ),
                            ),
                          ),
                          PopupMenuButton<_OrderDialogAction>(
                            onSelected: (action) async {
                              switch (action) {
                                case _OrderDialogAction.addFixed:
                                  final totalLocal = order.items.fold<double>(
                                    0,
                                    (s, it) => s + it.price * it.quantity,
                                  );
                                  final desc = order.items
                                      .map((e) =>
                                          '${e.product} x${e.quantity} (${e.price.toStringAsFixed(2)})')
                                      .join(', ');
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (!mounted) return;
                                  if (date != null) {
                                    final payment = FixedPayment(
                                      title: 'Pedido ${widget.supplier.name}',
                                      amount: totalLocal,
                                      startDate: date,
                                      frequency: FixedPaymentFrequency.monthly,
                                      description: desc.isEmpty ? null : desc,
                                      supplier: widget.supplier.name,
                                    );
                                    context
                                        .read<FixedPaymentBloc>()
                                        .add(FixedPaymentEvent.create(payment));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Añadido a pagos fijos'),
                                      ),
                                    );
                                  }
                                  break;
                                case _OrderDialogAction.delete:
                                  final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title:
                                              const Text('Eliminar pedido'),
                                          content: const Text(
                                              '¿Seguro que quieres eliminar este pedido?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                  if (!mounted) return;
                                  if (confirm) {
                                    setState(() {
                                      orders.removeAt(index);
                                    });
                                    final id = widget.supplier.id;
                                    if (id != null) {
                                      final updated = Supplier(
                                        id: id,
                                        name: widget.supplier.name,
                                        email: widget.supplier.email,
                                        phone: widget.supplier.phone,
                                        taxId: widget.supplier.taxId,
                                        fiscalAddress:
                                            widget.supplier.fiscalAddress,
                                        orderItems: const [],
                                        orders: orders,
                                      );
                                      context
                                          .read<SupplierBloc>()
                                          .add(SupplierEvent.update(updated));
                                    }
                                    Navigator.pop(context);
                                  }
                                  break;
                                case _OrderDialogAction.close:
                                  final newTitle = controller.text.trim();
                                  if (newTitle != (order.title ?? '').trim()) {
                                    final save = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title:
                                                const Text('Guardar cambios'),
                                            content: const Text(
                                                'Has cambiado el título. ¿Quieres guardar los cambios?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx)
                                                        .pop(false),
                                                child: const Text('No'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(true),
                                                child: const Text('Sí'),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;
                                    if (!mounted) return;
                                    if (save) {
                                      final updatedOrder = SupplierOrder(
                                        date: order.date,
                                        items: order.items,
                                        title:
                                            newTitle.isEmpty ? null : newTitle,
                                      );
                                      setState(() {
                                        orders[index] = updatedOrder;
                                      });
                                      final id = widget.supplier.id;
                                      if (id != null) {
                                        final updatedSupplier = Supplier(
                                          id: id,
                                          name: widget.supplier.name,
                                          email: widget.supplier.email,
                                          phone: widget.supplier.phone,
                                          taxId: widget.supplier.taxId,
                                          fiscalAddress:
                                              widget.supplier.fiscalAddress,
                                          orderItems: const [],
                                          orders: orders,
                                        );
                                        context
                                            .read<SupplierBloc>()
                                            .add(SupplierEvent.update(updatedSupplier));
                                      }
                                    }
                                  }
                                  Navigator.pop(context);
                                  break;
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: _OrderDialogAction.addFixed,
                                child: Text('Añadir a pagos fijos'),
                              ),
                              PopupMenuItem(
                                value: _OrderDialogAction.delete,
                                child: Text('Eliminar pedido'),
                              ),
                              PopupMenuItem(
                                value: _OrderDialogAction.close,
                                child: Text('Cerrar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(DateFormat('d/M/yy').format(order.date)),
                      const SizedBox(height: 8),
                      ...order.items.map(
                        (e) => Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '- ${e.product} x${e.quantity}  -  EUR ${(e.price * e.quantity).toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: EUR ${order.items.fold<double>(0, (s, it) => s + it.price * it.quantity).toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          final payments = state.fixedPayments
              .where(
                (p) => (p.supplier ?? '').toLowerCase() ==
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
                    onPressed: () => Navigator.pushNamed(
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
          final invoices = state.invoices
              .where(
                (i) => (i.issuer ?? '').toLowerCase() ==
                    widget.supplier.name.toLowerCase(),
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Facturas',
                  style: Theme.of(context).textTheme.titleMedium),
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
    final s = widget.supplier;
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
              s.name,
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
                      final phone = s.phone;
                      if (phone?.isNotEmpty == true) {
                        await launchUrl(Uri.parse('tel:$phone'));
                      }
                      break;
                    case _SupplierMenuOption.email:
                      final email = s.email;
                      if (email?.isNotEmpty == true) {
                        await launchUrl(Uri.parse('mailto:$email'));
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _SupplierMenuOption.edit,
                    child: Text('Editar'),
                  ),
                  const PopupMenuItem(
                    value: _SupplierMenuOption.delete,
                    child: Text('Eliminar'),
                  ),
                  if (s.phone?.isNotEmpty == true)
                    const PopupMenuItem(
                      value: _SupplierMenuOption.call,
                      child: Text('Llamar'),
                    ),
                  if (s.email?.isNotEmpty == true)
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
                      s.email?.isNotEmpty == true ? s.email! : 'Correo no disponible',
                ),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  value: s.phone?.isNotEmpty == true
                      ? s.phone!
                      : 'Teléfono no disponible',
                ),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  value:
                      s.taxId?.isNotEmpty == true ? 'NIF: ${s.taxId}' : 'NIF no disponible',
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  value: s.fiscalAddress?.isNotEmpty == true
                      ? s.fiscalAddress!
                      : 'Dirección fiscal no disponible',
                ),
                _buildSavedOrdersSection(),
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

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
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
enum _OrderDialogAction { addFixed, delete, close }

