import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_event.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/domain/usecases/user/self_employed_user_usecases.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

mixin CreateInvoiceViewModelMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // Campos del formulario
  String? title;
  DateTime invoiceDate = DateTime.now();
  double amount = 0.0;
  double iva = 0.0;
  bool isAmountIncludingIva = false;
  bool showAdvancedFields = false;
  InvoiceStatus status = InvoiceStatus.pending;
  File? invoiceImage;
  final ImagePicker picker = ImagePicker();

  // User profile
  SelfEmployedUser? selfEmployedUser;

  // Controllers for advanced fields
  final TextEditingController issuerController = TextEditingController();
  final TextEditingController receiverController = TextEditingController();
  final TextEditingController conceptController = TextEditingController();

  // Campos adicionales
  String? issuer;
  String? receiver;
  String? concept;

  // Getters
  double get total => amount + iva;

  // Validación y cálculo
  bool validateForm() {
    final isValid = formKey.currentState?.validate() ?? false;
    if (isValid) {
      formKey.currentState?.save();
      updateIva();
    }

    return isValid;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final result = await context.read<SelfEmployedUserUseCases>().getUser(
      userId,
    );
    result.fold((_) {}, (user) {
      setState(() {
        selfEmployedUser = user;
      });
    });
  }

  void updateIva() {
    if (isAmountIncludingIva) {
      double neto = amount / 1.21;
      iva = amount - neto;
      amount = neto;
    }
  }

  // Conversión a entidad Invoice
  Invoice toInvoice({String? id}) {
    return Invoice(
      id: id,
      title: title ?? '',
      date: invoiceDate,
      netAmount: amount,
      iva: iva,
      status: status,
      issuer: issuer,
      receiver: receiver,
      concept: concept,
      image: invoiceImage,
    );
  }

  Future<void> submitInvoice() async {
    if (!validateForm()) return;

    final invoice = toInvoice();

    context.read<InvoiceBloc>().add(InvoiceEvent.create(invoice)); // CORREGIDO

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Factura enviada correctamente")),
    );

    // Limpiar el formulario
    formKey.currentState?.reset();
    setState(() {
      amount = 0.0;
      iva = 0.0;
      invoiceImage = null;
      isAmountIncludingIva = false;
      status = InvoiceStatus.pending;
      title = null;
      issuer = null;
      receiver = null;
      concept = null;
      issuerController.clear();
      receiverController.clear();
      conceptController.clear();
      invoiceDate = DateTime.now();
    });
  }

  // Selección de imagen
  Future<void> pickImage({ImageSource source = ImageSource.camera}) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        invoiceImage = File(pickedFile.path);
      });
    }
  }

  void removeImage() {
    setState(() {
      invoiceImage = null;
    });
  }

  @override
  void dispose() {
    issuerController.dispose();
    receiverController.dispose();
    conceptController.dispose();
    super.dispose();
  }

  // Selección de fecha
  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.purple,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != invoiceDate) {
      setState(() {
        invoiceDate = picked;
      });
    }
  }

  // Generación y compartición de PDF
  Future<void> generateAndSharePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Factura', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 12),
              pw.Text('Título: $title'),
              pw.Text('Fecha: ${invoiceDate.toLocal()}'.split(' ')[0]),
              pw.Text('Importe neto: €${amount.toStringAsFixed(2)}'),
              pw.Text('IVA: €${iva.toStringAsFixed(2)}'),
              pw.Text('Total: €${total.toStringAsFixed(2)}'),
              pw.Text('Estado: ${status.name}'),
              if (invoiceImage != null)
                pw.Column(
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Text('Imagen de factura:'),
                    pw.SizedBox(height: 8),
                    pw.Image(pw.MemoryImage(invoiceImage!.readAsBytesSync())),
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
      name: 'factura.pdf',
      mimeType: 'application/pdf',
    );

    await SharePlus.instance.share(
      ShareParams(files: [xfile], text: 'Aquí está tu factura generada'),
    );
  }
}
