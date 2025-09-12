import 'package:flutter/material.dart';
import 'clients/application/view/clients_section.dart';
import 'suppliers/application/view/suppliers_section.dart';
import 'suppliers/bloc/supplier_bloc.dart';
import 'suppliers/bloc/supplier_state.dart';
import 'suppliers/application/view/create_supplier_sheet.dart';
import 'clients/bloc/client_bloc.dart';
import 'clients/bloc/client_state.dart';
import 'clients/application/view/create_client_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RelationshipsPage extends StatefulWidget {
  const RelationshipsPage({super.key});
  @override
  State<RelationshipsPage> createState() => _RelationshipsPageState();
}

class _RelationshipsPageState extends State<RelationshipsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientBloc, ClientState>(
      builder: (context, clientState) {
        return BlocBuilder<SupplierBloc, SupplierState>(
          builder: (context, supplierState) {
            final showAddClient =
                clientState is ClientLoaded && clientState.clients.isNotEmpty;
            final showAddSupplier =
                supplierState is SupplierLoaded &&
                supplierState.suppliers.isNotEmpty;

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                toolbarHeight: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Clientes'),
                            Visibility(
                              visible: showAddClient,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: Tooltip(
                                message: 'Crear cliente',
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => const CreateClientSheet(),
                                  ),
                                  child: const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Center(
                                      child: Icon(
                                        Icons.add_circle_outline,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Proveedores'),
                            Visibility(
                              visible: showAddSupplier,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: Tooltip(
                                message: 'Crear proveedor',
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => const CreateSupplierSheet(),
                                  ),
                                  child: const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Center(
                                      child: Icon(
                                        Icons.add_circle_outline,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: const [ClientsSection(), SuppliersSection()],
              ),
            );
          },
        );
      },
    );
  }
}
