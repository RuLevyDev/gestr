import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/relationships/clients/application/view/clients_section.dart';
import 'package:gestr/app/relationships/clients/bloc/client_bloc.dart';
import 'package:gestr/app/relationships/clients/bloc/client_event.dart';
import 'package:gestr/domain/entities/client.dart';
import '../view/create_client_sheet.dart';

mixin ClientsSectionMixin on State<ClientsSection> {
  Widget buildEmptyMessage(bool isDark) {
    final color = isDark ? Colors.lightBlueAccent : Colors.blue;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              'No hay clientes todavía.',
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer cliente para comenzar a gestionarlos.',
              style: TextStyle(fontSize: 14, color: color.withAlpha(180)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const CreateClientSheet(),
                  ),
              icon: const Icon(Icons.add),
              label: const Text('Crear cliente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmDelete(Client client) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text('Eliminar cliente'),
                content: Text('¿Eliminar "${client.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
        ) ??
        false;
    if (!mounted) return;
    if (ok && client.id != null) {
      context.read<ClientBloc>().add(ClientEvent.delete(client.id!));
    }
  }
}
