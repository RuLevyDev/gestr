import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/relationships/clients/application/view/client_detail_dialog.dart';
import 'package:gestr/app/relationships/clients/bloc/client_bloc.dart';
import 'package:gestr/app/relationships/clients/bloc/client_event.dart';
import 'package:gestr/app/relationships/clients/bloc/client_state.dart';
import 'package:gestr/domain/entities/client.dart';

import '../../widgets/client_card.dart';
import 'create_client_sheet.dart';
import '../viewmodel/clients_section_mixin.dart';

class ClientsSection extends StatefulWidget {
  const ClientsSection({super.key});

  @override
  State<ClientsSection> createState() => _ClientsSectionState();
}

class _ClientsSectionState extends State<ClientsSection>
    with ClientsSectionMixin {
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
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return clients.isEmpty
                    ? buildEmptyMessage(isDark)
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: clients.length,
                      itemBuilder: (context, i) {
                        final cl = clients[i];
                        return ClientCard(
                          client: cl,
                          onTap: () => _openDetail(cl),
                          onDelete: () => confirmDelete(cl),
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
            onDelete: () => confirmDelete(client),
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
}
