import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/relationships/clients/application/view/client_detail_dialog.dart';

import 'package:gestr/app/relationships/clients/bloc/client_bloc.dart';
import 'package:gestr/app/relationships/clients/bloc/client_event.dart';
import 'package:gestr/app/relationships/clients/bloc/client_state.dart';
import 'package:gestr/domain/entities/client.dart';

import '../../widgets/client_card.dart';
import 'create_client_sheet.dart';

class ClientsSection extends StatefulWidget {
  const ClientsSection({super.key});

  @override
  State<ClientsSection> createState() => _ClientsSectionState();
}

class _ClientsSectionState extends State<ClientsSection> {
  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(const ClientEvent.fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42.0, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BlocBuilder<ClientBloc, ClientState>(
              builder: (context, state) {
                if (state is ClientLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ClientError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                if (state is! ClientLoaded) {
                  return const SizedBox.shrink();
                }
                final clients = state.clients;
                return clients.isEmpty
                    ? _buildEmptyMessage()
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: clients.length,
                      itemBuilder: (context, i) {
                        final cl = clients[i];
                        return ClientCard(
                          client: cl,
                          onTap: () => _openDetail(cl),
                          onDelete: () => _confirmDelete(cl),
                        );
                      },
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(Client client) {
    showDialog(
      context: context,
      builder:
          (_) => ClientDetailDialog(
            client: client,
            onEdit: () => _editClient(client),
            onDelete: () => _confirmDelete(client),
          ),
    );
  }

  void _editClient(Client client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateClientSheet(initialName: client.name),
    );
  }

  Widget _buildEmptyMessage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

  void _confirmDelete(Client client) async {
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
    if (!mounted) {
      return;
    }
    if (ok && client.id != null) {
      context.read<ClientBloc>().add(ClientEvent.delete(client.id!));
    }
  }
}
