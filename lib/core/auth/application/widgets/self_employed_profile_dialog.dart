import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/core/utils/dialog_background.dart';

import 'package:gestr/core/auth/application/viewmodels/self_employed_profile_viewmodel.dart';
import 'package:gestr/core/auth/bloc/self_employed_bloc.dart';
import 'package:gestr/core/auth/bloc/self_employed_state.dart';

class SelfEmployedProfileDialog extends StatefulWidget {
  final void Function(SelfEmployedUser user) onSave;
  final String uid;

  const SelfEmployedProfileDialog({
    required this.uid,
    required this.onSave,
    super.key,
  });

  @override
  State<SelfEmployedProfileDialog> createState() =>
      _SelfEmployedProfileDialogState();
}

class _SelfEmployedProfileDialogState extends State<SelfEmployedProfileDialog>
    with SelfEmployedProfileDialogViewModelMixin {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SelfEmployedBloc, SelfEmployedState>(
      listener: (context, state) {
        if (state is SelfEmployedSaved) {
          Navigator.of(context).pop();
        } else if (state is SelfEmployedError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
        }
      },
      builder: (context, state) {
        final isLoading = state is SelfEmployedLoading;

        return Dialog(
          insetPadding: EdgeInsets.all(12),
          backgroundColor: Colors.transparent,
          child: IntrinsicHeight(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DialogBackground(), // El fondo animado
                  ),
                  AlertDialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.all(12),
                    title: const Text('Completa tu perfil'),
                    content: SizedBox(
                      width: 520,
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (currentStep == 0) ...[
                                // Campos del primer paso
                                TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre completo',
                                  ),
                                  validator:
                                      (value) =>
                                          value!.isEmpty
                                              ? 'Campo obligatorio'
                                              : null,
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: dniController,
                                  decoration: const InputDecoration(
                                    labelText: 'DNI',
                                  ),
                                  validator: validateDNI,
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: activityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Actividad',
                                  ),
                                  validator:
                                      (value) =>
                                          value!.isEmpty
                                              ? 'Campo obligatorio'
                                              : null,
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: startDateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha de inicio',
                                  ),
                                  readOnly: true,
                                  onTap: () => pickStartDate(context),
                                  validator:
                                      (value) =>
                                          selectedStartDate == null
                                              ? 'Selecciona una fecha de inicio'
                                              : null,
                                ),
                                SizedBox(height: 8),
                                DropdownButtonFormField<double>(
                                  decoration: const InputDecoration(
                                    labelText: 'IVA gasto por defecto',
                                  ),
                                  initialValue: defaultExpenseVatRate,
                                  items: const [0.0, 0.04, 0.10, 0.21]
                                      .map((r) => DropdownMenuItem(
                                            value: r,
                                            child: Text('${(r * 100).toStringAsFixed(0)}%'),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => defaultExpenseVatRate = v ?? 0.0),
                                ),
                                SwitchListTile(
                                  title: const Text('Gasto incluye IVA por defecto'),
                                  value: defaultExpenseAmountIsGross,
                                  onChanged: (v) => setState(() => defaultExpenseAmountIsGross = v),
                                ),
                                SwitchListTile(
                                  title: const Text('Gasto deducible por defecto'),
                                  value: defaultExpenseDeductible,
                                  onChanged: (v) => setState(() => defaultExpenseDeductible = v),
                                ),
                                SizedBox(height: 8),
                                DropdownButtonFormField<double>(
                                  decoration: const InputDecoration(
                                    labelText: 'IVA gasto por defecto',
                                  ),
                                  initialValue: defaultExpenseVatRate,
                                  items: const [0.0, 0.04, 0.10, 0.21]
                                      .map((r) => DropdownMenuItem(
                                            value: r,
                                            child: Text('${(r * 100).toStringAsFixed(0)}%'),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => defaultExpenseVatRate = v ?? 0.0),
                                ),
                                SwitchListTile(
                                  title: const Text('Gasto incluye IVA por defecto'),
                                  value: defaultExpenseAmountIsGross,
                                  onChanged: (v) => setState(() => defaultExpenseAmountIsGross = v),
                                ),
                                SwitchListTile(
                                  title: const Text('Gasto deducible por defecto'),
                                  value: defaultExpenseDeductible,
                                  onChanged: (v) => setState(() => defaultExpenseDeductible = v),
                                ),
                              ],
                              if (currentStep == 1) ...[
                                // Campos del segundo paso
                                TextFormField(
                                  controller: addressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Dirección',
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: ibanController,
                                  decoration: const InputDecoration(
                                    labelText: 'IBAN',
                                  ),
                                  validator: validateIBAN,
                                ),
                                SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Método de tributación',
                                  ),
                                  initialValue: taxationMethod,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Estimación directa',
                                      child: Text(
                                        'Estimación directa',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Estimación objetiva',
                                      child: Text(
                                        'Estimación objetiva',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      taxationMethod = value!;
                                    });
                                  },
                                ),
                                SizedBox(height: 8),
                                SwitchListTile(
                                  title: const Text(
                                    '¿Usa facturación electrónica?',
                                  ),
                                  value: usesElectronicInvoicing,
                                  onChanged: (val) {
                                    setState(() {
                                      usesElectronicInvoicing = val;
                                    });
                                  },
                                ),
                              ],
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 24.0,
                                  bottom: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(2, (index) {
                                    return _buildStepIndicator(index);
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  if (currentStep == 0) {
                                    if (formKey.currentState!.validate()) {
                                      setState(() {
                                        currentStep++;
                                      });
                                    }
                                  } else if (currentStep == 1) {
                                    submitProfile(widget.uid, widget.onSave);
                                  }
                                },
                        child:
                            isLoading
                                ? CircularProgressIndicator()
                                : Text(
                                  currentStep == 1 ? 'Guardar' : 'Continuar',
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(int step) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: step == currentStep ? 24 : 6,
      height: 6,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: step <= currentStep ? Colors.teal : Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
