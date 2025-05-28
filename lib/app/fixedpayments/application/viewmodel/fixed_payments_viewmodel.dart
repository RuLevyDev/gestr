import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

mixin CreateFixedPaymentViewModelMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // Campos del formulario
  String? title;
  double amount = 0.0;
  DateTime startDate = DateTime.now();
  FixedPaymentFrequency frequency = FixedPaymentFrequency.monthly;
  String? description;
  File? proofImage;
  final ImagePicker picker = ImagePicker();

  bool validateForm() {
    final isValid = formKey.currentState?.validate() ?? false;
    if (isValid) formKey.currentState?.save();
    return isValid;
  }

  FixedPayment toFixedPayment({String? id}) {
    return FixedPayment(
      id: id,
      title: title ?? '',
      amount: amount,
      startDate: startDate,
      frequency: frequency,
      description: description,
      image: proofImage,
    );
  }

  Future<void> submitFixedPayment() async {
    if (!validateForm()) return;

    final payment = toFixedPayment();

    final completer = Completer<void>();

    final subscription = context.read<FixedPaymentBloc>().stream.listen((
      state,
    ) {
      if (state is FixedPaymentLoaded) {
        completer.complete();
      } else if (state is FixedPaymentError) {
        completer.completeError(state.message);
      }
    });

    context.read<FixedPaymentBloc>().add(FixedPaymentEvent.create(payment));

    try {
      await completer.future;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pago fijo creado correctamente")),
      );
      formKey.currentState?.reset();
      setState(() {
        title = null;
        amount = 0.0;
        description = null;
        proofImage = null;
        frequency = FixedPaymentFrequency.monthly;
        startDate = DateTime.now();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al guardar el pago: $e")));
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> pickImage({ImageSource source = ImageSource.camera}) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        proofImage = File(pickedFile.path);
      });
    }
  }

  void removeImage() {
    setState(() {
      proofImage = null;
    });
  }

  Future<void> selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> generateAndSharePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Pago Fijo', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 12),
              pw.Text('Título: $title'),
              pw.Text('Fecha de inicio: ${startDate.toLocal()}'.split(' ')[0]),
              pw.Text('Importe: €${amount.toStringAsFixed(2)}'),
              pw.Text('Frecuencia: ${frequency.name}'),
              if (description != null && description!.isNotEmpty)
                pw.Text('Descripción: $description'),
              if (proofImage != null)
                pw.Column(
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Text('Comprobante:'),
                    pw.SizedBox(height: 8),
                    pw.Image(pw.MemoryImage(proofImage!.readAsBytesSync())),
                  ],
                ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final xfile = XFile.fromData(
      bytes,
      name: 'pago_fijo.pdf',
      mimeType: 'application/pdf',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xfile],
        text: 'Aquí está el comprobante del pago fijo',
      ),
    );
  }
}
