import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/clients/bloc/client_bloc.dart';
import 'package:gestr/app/clients/bloc/client_event.dart';
import 'package:gestr/app/clients/bloc/client_state.dart';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clientes',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 28),
                tooltip: 'Crear cliente',
                onPressed:
                    () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const CreateClientSheet(),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                    ? const Center(child: Text('No hay clientes todavía.'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: clients.length,
                      itemBuilder: (context, i) {
                        final cl = clients[i];
                        return ClientCard(
                          client: cl,
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
