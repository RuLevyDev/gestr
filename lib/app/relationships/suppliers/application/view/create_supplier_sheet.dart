import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_event.dart';
import 'package:gestr/domain/entities/supplier.dart';

class CreateSupplierSheet extends StatefulWidget {
  /// If provided, the sheet behaves as an edit form and pre-fills fields.
  final Supplier? supplier;
  /// Optional convenience for create-mode prefill.
  final String? initialName;
  const CreateSupplierSheet({super.key, this.supplier, this.initialName});

  @override
  State<CreateSupplierSheet> createState() => _CreateSupplierSheetState();
}

class _CreateSupplierSheetState extends State<CreateSupplierSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sp = widget.supplier;
    if (sp != null) {
      _nameCtrl.text = sp.name;
      _emailCtrl.text = sp.email ?? '';
      _phoneCtrl.text = sp.phone ?? '';
      _taxIdCtrl.text = sp.taxId ?? '';
      _addressCtrl.text = sp.fiscalAddress ?? '';
    } else if (widget.initialName != null) {
      _nameCtrl.text = widget.initialName!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _taxIdCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.supplier == null ? 'Nuevo proveedor' : 'Editar proveedor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator:
                  (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email (opcional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taxIdCtrl,
              decoration: const InputDecoration(labelText: 'NIF (opcional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección fiscal (opcional)',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_alt),
              label: const Text('Guardar'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final editing = widget.supplier != null;
    final base = widget.supplier;
    final supplier = Supplier(
      id: base?.id,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      taxId: _taxIdCtrl.text.trim().isEmpty ? null : _taxIdCtrl.text.trim(),
      fiscalAddress:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      // Preserve existing order-related fields on edit
      orderItems: base?.orderItems ?? const [],
      orders: base?.orders ?? const [],
    );
    if (editing) {
      context.read<SupplierBloc>().add(SupplierEvent.update(supplier));
    } else {
      context.read<SupplierBloc>().add(SupplierEvent.create(supplier));
    }
    Navigator.pop(context);
  }
}
