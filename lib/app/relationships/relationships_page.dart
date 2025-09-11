import 'package:flutter/material.dart';
import 'clients/application/view/clients_section.dart';
import 'suppliers/application/view/suppliers_section.dart';

class RelationshipsPage extends StatelessWidget {
  const RelationshipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [Tab(text: 'Clientes'), Tab(text: 'Proveedores')],
          ),
        ),
        body: const TabBarView(
          children: [ClientsSection(), SuppliersSection()],
        ),
      ),
    );
  }
}
