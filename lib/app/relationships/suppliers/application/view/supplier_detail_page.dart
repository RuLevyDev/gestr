import 'package:flutter/material.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:url_launcher/url_launcher.dart';

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

  double get _total => _items.fold(0, (sum, item) => sum + item.price);

  void _addItem() {
    setState(() {
      _items.add(_OrderItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
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
                const SizedBox(height: 24),
                Text(
                  'Desglose del pedido',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < _items.length; i++)
                  _ItemRow(
                    item: _items[i],
                    onRemove: () => _removeItem(i),
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
                    child: Text('Total: €${_total.toStringAsFixed(2)}'),
                  ),
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

  double get price =>
      double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;

  void dispose() {
    productController.dispose();
    priceController.dispose();
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
