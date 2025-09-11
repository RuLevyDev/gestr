import 'package:flutter/material.dart';
import '../viewmodel/create_client_viewmodel.dart';

class CreateClientSheet extends StatefulWidget {
  final String? initialName;
  const CreateClientSheet({super.key, this.initialName});

  @override
  State<CreateClientSheet> createState() => _CreateClientSheetState();
}

class _CreateClientSheetState extends State<CreateClientSheet>
    with CreateClientViewModelMixin<CreateClientSheet> {
  @override
  String? get initialName => widget.initialName;

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
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nuevo cliente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator:
                  (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email (opcional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: taxIdCtrl,
              decoration: const InputDecoration(labelText: 'NIF (opcional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección fiscal (opcional)',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save_alt),
              label: const Text('Guardar'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
