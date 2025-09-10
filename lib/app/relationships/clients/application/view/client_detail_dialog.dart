import 'package:flutter/material.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
import 'package:gestr/domain/entities/client.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientDetailDialog extends StatelessWidget {
  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ClientDetailDialog({
    super.key,
    required this.client,
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
                          client.name,
                          style: theme.textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<_ClientMenuOption>(
                        onSelected: (option) async {
                          switch (option) {
                            case _ClientMenuOption.edit:
                              Navigator.pop(context);
                              onEdit();
                              break;
                            case _ClientMenuOption.delete:
                              Navigator.pop(context);
                              onDelete();
                              break;
                            case _ClientMenuOption.call:
                              final phone = client.phone;
                              if (phone?.isNotEmpty == true) {
                                await launchUrl(Uri.parse('tel:$phone'));
                              }
                              break;
                            case _ClientMenuOption.email:
                              final email = client.email;
                              if (email?.isNotEmpty == true) {
                                await launchUrl(Uri.parse('mailto:$email'));
                              }
                              break;
                          }
                        },
                        itemBuilder: (context) {
                          return [
                            const PopupMenuItem(
                              value: _ClientMenuOption.edit,
                              child: Text('Editar'),
                            ),
                            const PopupMenuItem(
                              value: _ClientMenuOption.delete,
                              child: Text('Eliminar'),
                            ),
                            if (client.phone?.isNotEmpty == true)
                              const PopupMenuItem(
                                value: _ClientMenuOption.call,
                                child: Text('Llamar'),
                              ),
                            if (client.email?.isNotEmpty == true)
                              const PopupMenuItem(
                                value: _ClientMenuOption.email,
                                child: Text('Enviar correo'),
                              ),
                          ];
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    value:
                        client.email?.isNotEmpty == true
                            ? client.email!
                            : 'Correo no disponible',
                  ),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    value:
                        client.phone?.isNotEmpty == true
                            ? client.phone!
                            : 'Teléfono no disponible',
                  ),
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    value:
                        client.taxId?.isNotEmpty == true
                            ? 'NIF: ${client.taxId}'
                            : 'NIF no disponible',
                  ),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    value:
                        client.fiscalAddress?.isNotEmpty == true
                            ? client.fiscalAddress!
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

enum _ClientMenuOption { edit, delete, call, email }
