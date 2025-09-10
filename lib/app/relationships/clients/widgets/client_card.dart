import 'package:flutter/material.dart';
import 'package:gestr/domain/entities/client.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback? onDelete;

  const ClientCard({super.key, required this.client, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.deepPurple.withValues(alpha: 0.18)
                  : Colors.teal.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (client.taxId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'NIF: ${client.taxId!}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (client.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      client.email!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
