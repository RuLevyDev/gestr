import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/relationships/clients/bloc/client_bloc.dart';
import 'package:gestr/app/relationships/clients/bloc/client_event.dart';
import 'package:gestr/domain/entities/client.dart';

class CreateClientSheet extends StatefulWidget {
  final String? initialName;
  const CreateClientSheet({super.key, this.initialName});

  @override
  State<CreateClientSheet> createState() => _CreateClientSheetState();
}

class _CreateClientSheetState extends State<CreateClientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
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
              'Nuevo cliente',
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
    final client = Client(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      taxId: _taxIdCtrl.text.trim().isEmpty ? null : _taxIdCtrl.text.trim(),
      fiscalAddress:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
    );
    context.read<ClientBloc>().add(ClientEvent.create(client));
    Navigator.pop(context);
  }
}
