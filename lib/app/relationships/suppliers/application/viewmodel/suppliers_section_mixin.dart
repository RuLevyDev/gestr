import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/relationships/suppliers/application/view/suppliers_section.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_event.dart';
import 'package:gestr/domain/entities/supplier.dart';

mixin SuppliersSectionMixin on State<SuppliersSection> {
  Widget buildEmptyMessage(bool isDark, VoidCallback onCreate) {
    final color = isDark ? Colors.orangeAccent : Colors.orange;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory_outlined, size: 48, color: color),
            const SizedBox(height: 12),
            Text('No hay proveedores todavía.',
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Crea tu primer proveedor para comenzar a gestionarlos.',
              style: TextStyle(fontSize: 14, color: color.withAlpha(180)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear proveedor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> confirmDelete(Supplier supplier) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminar proveedor'),
            content: Text('¿Eliminar "' + supplier.name + '"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
            ],
          ),
        ) ?? false;
    if (!mounted) return false;
    if (ok && supplier.id != null) {
      context.read<SupplierBloc>().add(SupplierEvent.delete(supplier.id!));
      return true;
    }
    return false;
  }
}


