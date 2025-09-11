import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/relationships/clients/bloc/client_bloc.dart';
import 'package:gestr/app/relationships/clients/bloc/client_event.dart';
import 'package:gestr/domain/entities/client.dart';

mixin CreateClientViewModelMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final taxIdCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  String? get initialName => null;

  @override
  void initState() {
    super.initState();
    final name = initialName;
    if (name != null) {
      nameCtrl.text = name;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    taxIdCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  void save() {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    final client = Client(
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      taxId: taxIdCtrl.text.trim().isEmpty ? null : taxIdCtrl.text.trim(),
      fiscalAddress:
          addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
    );
    context.read<ClientBloc>().add(ClientEvent.create(client));
    Navigator.pop(context);
  }
}
