import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';

import 'package:gestr/domain/entities/supplier.dart';

import 'package:gestr/app/relationships/suppliers/application/view/supplier_detail_types.dart';
import 'package:gestr/app/relationships/suppliers/application/viewmodel/supplier_detail_viewmodel.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/supplier_order_items_section.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/supplier_saved_orders_section.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/supplier_fixed_payments_section.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/supplier_invoices_section.dart';

import 'package:gestr/app/relationships/suppliers/application/widgets/info_row.dart';

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
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            title: Center(
              child: Text(
                s.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            actions: [
              PopupMenuButton<SupplierMenuOption>(
                onSelected: (option) async {
                  switch (option) {
                    case SupplierMenuOption.edit:
                      await widget.onEdit();
                      break;
                    case SupplierMenuOption.delete:
                      final deleted = await widget.onDelete();
                      if (deleted && context.mounted) {
                        Navigator.of(context).pop();
                      }
                      break;
                    case SupplierMenuOption.call:
                      final phone = s.phone;
                      if (phone?.isNotEmpty == true) {
                        await launchUrl(Uri.parse('tel:$phone'));
                      }
                      break;
                    case SupplierMenuOption.email:
                      final email = s.email;
                      if (email?.isNotEmpty == true) {
                        await launchUrl(Uri.parse('mailto:$email'));
                      }
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: SupplierMenuOption.edit,
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: SupplierMenuOption.delete,
                        child: Text('Eliminar'),
                      ),
                      if (s.phone?.isNotEmpty == true)
                        const PopupMenuItem(
                          value: SupplierMenuOption.call,
                          child: Text('Llamar'),
                        ),
                      if (s.email?.isNotEmpty == true)
                        const PopupMenuItem(
                          value: SupplierMenuOption.email,
                          child: Text('Enviar correo'),
                        ),
                    ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.email?.isNotEmpty == true)
                  InfoRow(icon: Icons.email_outlined, value: s.email!),
                if (s.phone?.isNotEmpty == true)
                  InfoRow(icon: Icons.phone_outlined, value: s.phone!),
                if (s.taxId?.isNotEmpty == true)
                  InfoRow(icon: Icons.badge_outlined, value: 'NIF: ${s.taxId}'),
                if (s.fiscalAddress?.isNotEmpty == true)
                  InfoRow(
                    icon: Icons.location_on_outlined,
                    value: s.fiscalAddress!,
                  ),
                const SizedBox(height: 12),

                if (orders.isEmpty) ...[
                  Text(
                    'Nuevo pedido o producto',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _buildOrderItemsSection(),
                ],

                SupplierSavedOrdersSection(
                  orders: orders,
                  supplierName: widget.supplier.name,
                  onTap: (i) => showOrderDetailsDialog(i),
                  onAdd: () async {
                    // Hacer visible el editor debajo del wrap y preparar primer ítem
                    if (items.isEmpty) addItem();
                    // No abrir bottom sheet: se edita inline
                    setState(() {});
                  },
                ),
                if (orders.isNotEmpty && items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildOrderItemsSection(),
                  Divider(
                    height: 22,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ],
                Divider(
                  height: 12,
                  color: Theme.of(context).colorScheme.tertiary,
                ),

                _buildFixedPaymentsSection(),
                Divider(
                  height: 12,
                  color: Theme.of(context).colorScheme.tertiary,
                ),

                _buildInvoicesSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemsSection() {
    return SupplierOrderItemsSection(
      items: items,
      onAdd: addItem,
      onRemove: (i) => handleRemoveItem(i),
      onChanged: () => setState(() {}),
      total: total,
      onSave: () => saveOrder(context),
      canSave: canSaveCurrentOrder,
    );
  }

  Widget _buildFixedPaymentsSection() {
    return SupplierFixedPaymentsSection(supplierName: widget.supplier.name);
  }

  Widget _buildInvoicesSection() {
    return SupplierInvoicesSection(supplierName: widget.supplier.name);
  }
}
