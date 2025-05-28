import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/app/auth/bloc/self_employed_bloc.dart';
import 'package:gestr/app/auth/bloc/self_employed_event.dart';

mixin SelfEmployedProfileDialogViewModelMixin<T extends StatefulWidget>
    on State<T> {
  final nameController = TextEditingController();
  final dniController = TextEditingController();
  final activityController = TextEditingController();
  final startDateController = TextEditingController();
  final addressController = TextEditingController();
  final ibanController = TextEditingController();

  bool usesElectronicInvoicing = false;
  String taxationMethod = 'Estimación directa';
  DateTime? selectedStartDate;
  final formKey = GlobalKey<FormState>();
  int currentStep = 0;

  void pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2025),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked;
        startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String? validateDNI(String? value) {
    final dniRegExp = RegExp(r'^\d{8}[A-Za-z]$');
    if (value == null || value.isEmpty) {
      return 'Campo obligatorio';
    } else if (!dniRegExp.hasMatch(value)) {
      return 'DNI no válido';
    }
    return null;
  }

  String? validateIBAN(String? value) {
    final ibanRegExp = RegExp(
      r'^[A-Z]{2}\d{2}[A-Z0-9]{4}[A-Z0-9]{4}[A-Z0-9]{4}[A-Z0-9]{4}$',
    );
    if (value == null || value.isEmpty) {
      return 'Campo obligatorio';
    } else if (!ibanRegExp.hasMatch(value)) {
      return 'IBAN no válido';
    }
    return null;
  }

  void submitProfile(String uid, void Function(SelfEmployedUser user) onSave) {
    if (formKey.currentState!.validate() && selectedStartDate != null) {
      final user = SelfEmployedUser(
        uid: uid,
        fullName: nameController.text.trim(),
        dni: dniController.text.trim(),
        activity: activityController.text.trim(),
        startDate: selectedStartDate!,
        address: addressController.text.trim(),
        iban: ibanController.text.trim(),
        usesElectronicInvoicing: usesElectronicInvoicing,
        taxationMethod: taxationMethod,
      );
      context.read<SelfEmployedBloc>().add(SaveSelfEmployedUser(user));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    dniController.dispose();
    activityController.dispose();
    startDateController.dispose();
    addressController.dispose();
    ibanController.dispose();
    super.dispose();
  }
}
