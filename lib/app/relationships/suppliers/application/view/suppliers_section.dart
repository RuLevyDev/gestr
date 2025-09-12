import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gestr/app/relationships/suppliers/application/view/supplier_detail_page.dart';
import 'package:gestr/app/relationships/suppliers/application/viewmodel/suppliers_section_mixin.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/supplier_card.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_event.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_state.dart';
import 'package:gestr/domain/entities/supplier.dart';

import 'create_supplier_sheet.dart';

class SuppliersSection extends StatefulWidget {
  const SuppliersSection({super.key});
  @override
  State<SuppliersSection> createState() => _SuppliersSectionState();
}

class _SuppliersSectionState extends State<SuppliersSection>
    with SuppliersSectionMixin {
  @override
  void initState() {
    super.initState();
    context.read<SupplierBloc>().add(const SupplierEvent.fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42.0, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BlocBuilder<SupplierBloc, SupplierState>(
              builder: (context, state) {
                if (state is SupplierLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SupplierError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                if (state is! SupplierLoaded) {
                  return const SizedBox.shrink();
                }
                final suppliers = state.suppliers;
                return suppliers.isEmpty
                    ? buildEmptyMessage(
                      Theme.of(context).brightness == Brightness.dark,
                      () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const CreateSupplierSheet(),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: suppliers.length,
                      itemBuilder: (context, i) {
                        final sp = suppliers[i];
                        return SupplierCard(
                          supplier: sp,
                          onTap: () => _openDetail(sp),
                          onDelete: () => confirmDelete(sp),
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

  void _openDetail(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SupplierDetailPage(
              supplier: supplier,
              onEdit: () => _editSupplier(supplier),
              onDelete: () => confirmDelete(supplier),
            ),
      ),
    );
  }

  Future<void> _editSupplier(Supplier supplier) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateSupplierSheet(supplier: supplier),
    );
  }
}
