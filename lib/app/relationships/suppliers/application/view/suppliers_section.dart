import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/relationships/suppliers/application/view/supplier_detail_page.dart';
import 'package:gestr/app/relationships/suppliers/application/viewmodel/suppliers_section_mixin.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_event.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_state.dart';
import 'package:gestr/domain/entities/supplier.dart';
import '../widgets/supplier_card.dart';
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
                    ? _buildEmptyMessage()
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: suppliers.length,
                      itemBuilder: (context, i) {
                        final sp = suppliers[i];
                        return SupplierCard(
                          supplier: sp,
                          onTap: () => _openDetail(sp),
                          onDelete: () => _confirmDelete(sp),
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

  Widget _buildEmptyMessage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.lightGreenAccent : Colors.green;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              'No hay proveedores todavía.',
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer proveedor para comenzar a gestionarlos.',
              style: TextStyle(fontSize: 14, color: color.withAlpha(180)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const CreateSupplierSheet(),
                  ),
              icon: const Icon(Icons.add),
              label: const Text('Crear proveedor'),
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

  void _openDetail(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SupplierDetailPage(
              supplier: supplier,
              onEdit: () => _editSupplier(supplier),
              onDelete: () => _confirmDelete(supplier),
            ),
      ),
    );
  }

  Future<void> _editSupplier(Supplier supplier) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateSupplierSheet(initialName: supplier.name),
    );
  }

  Future<bool> _confirmDelete(Supplier supplier) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text('Eliminar proveedor'),
                content: Text('¿Eliminar "${supplier.name}"?'),
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
      return false;
    }
    if (ok && supplier.id != null) {
      context.read<SupplierBloc>().add(SupplierEvent.delete(supplier.id!));
      return true;
    }
    return false;
  }
}
