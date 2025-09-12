import 'package:flutter/material.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:url_launcher/url_launcher.dart';

class SupplierDetailDialog extends StatelessWidget {
  final Supplier supplier;
  final Future<void> Function() onEdit;
  final Future<bool> Function() onDelete;

  const SupplierDetailDialog({
    super.key,
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                        child: Text(
                          supplier.name,
                          style: theme.textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<_SupplierDetailMenuOption>(
                        onSelected: (option) async {
                          switch (option) {
                            case _SupplierDetailMenuOption.edit:
                              Navigator.pop(context);
                              await onEdit();
                              break;
                            case _SupplierDetailMenuOption.delete:
                              Navigator.pop(context);
                              final deleted = await onDelete();
                              if (deleted && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Proveedor eliminado'),
                                  ),
                                );
                              }
                              break;
                            case _SupplierDetailMenuOption.call:
                              final phone = supplier.phone;
                              if (phone?.isNotEmpty == true) {
                                await launchUrl(Uri.parse('tel:$phone'));
                              }
                              break;
                            case _SupplierDetailMenuOption.email:
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
                                value: _SupplierDetailMenuOption.edit,
                                child: Text('Editar'),
                              ),
                              const PopupMenuItem(
                                value: _SupplierDetailMenuOption.delete,
                                child: Text('Eliminar'),
                              ),
                              if (supplier.phone?.isNotEmpty == true)
                                const PopupMenuItem(
                                  value: _SupplierDetailMenuOption.call,
                                  child: Text('Llamar'),
                                ),
                              if (supplier.email?.isNotEmpty == true)
                                const PopupMenuItem(
                                  value: _SupplierDetailMenuOption.email,
                                  child: Text('Enviar correo'),
                                ),
                            ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                ],
              ),
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

enum _SupplierDetailMenuOption { edit, delete, call, email }
