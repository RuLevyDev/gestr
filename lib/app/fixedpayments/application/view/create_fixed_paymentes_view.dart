import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gestr/app/fixedpayments/application/viewmodel/fixed_payments_viewmodel.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:image_picker/image_picker.dart';

class CreateFixedPaymentPage extends StatefulWidget {
  const CreateFixedPaymentPage({super.key});

  @override
  State<CreateFixedPaymentPage> createState() => _CreateFixedPaymentPageState();
}

class _CreateFixedPaymentPageState extends State<CreateFixedPaymentPage>
    with CreateFixedPaymentViewModelMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadDefaults(context));
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: isDark ? const DialogBackground() : const BackgroundLight(),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Nuevo Pago Fijo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            backgroundColor: Colors.transparent,
            actions: [
              if (proofImage != null)
                IconButton(
                  onPressed: generateAndSharePdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Generar PDF',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _buildHeaderSection(theme),
                  const SizedBox(height: 16),
                  _buildDetailsSection(theme),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: submitFixedPayment,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar pago fijo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.tealAccent.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Título'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Campo obligatorio'
                            : null,
                onSaved: (value) => title = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción'),
                onSaved: (value) => description = value,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Inicio: ${DateFormat('yyyy-MM-dd').format(startDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: selectStartDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Cambiar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.tealAccent.withAlpha(80)),
          ),
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Importe (€)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final d = double.tryParse(value ?? '');
                  return (d == null || d < 0) ? 'Importe inválido' : null;
                },
                onChanged: (val) {
                  final d = double.tryParse(val);
                  if (d != null) setState(() => amount = d);
                },
                onSaved: (val) => amount = double.tryParse(val ?? '0') ?? 0,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Proveedor'),
                onSaved: (val) => supplier = val,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FixedPaymentCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: FixedPaymentCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.nameEs),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => category = v ?? FixedPaymentCategory.other),
                onSaved: (v) => category = v ?? FixedPaymentCategory.other,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                initialValue: vatRate,
                decoration: const InputDecoration(labelText: 'IVA (%)'),
                items: const [0.0, 0.04, 0.10, 0.21]
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text('${(r * 100).toStringAsFixed(0)}%'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => vatRate = v ?? 0.0),
                onSaved: (v) => vatRate = v ?? 0.0,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Importe incluye IVA'),
                value: amountIsGross,
                onChanged: (v) => setState(() => amountIsGross = v),
              ),
              SwitchListTile(
                title: const Text('Gasto deducible'),
                value: deductible,
                onChanged: (v) => setState(() => deductible = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FixedPaymentFrequency>(
                initialValue: frequency,
                decoration: const InputDecoration(labelText: 'Frecuencia'),
                items:
                    FixedPaymentFrequency.values.map((f) {
                      return DropdownMenuItem(value: f, child: Text(f.name));
                    }).toList(),
                onChanged: (val) => setState(() => frequency = val!),
                onSaved: (val) => frequency = val!,
              ),
              const SizedBox(height: 16),
              _buildImageSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    if (proofImage == null) {
      return Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => pickImage(source: ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Foto'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => pickImage(source: ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comprobante seleccionado:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(proofImage!, height: 180, fit: BoxFit.cover),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: removeImage,
                tooltip: 'Eliminar imagen',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
