import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/domain/usecases/user/self_employed_user_usecases.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/core/image/aeat_image_support.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gestr/core/pdf/pdfa_utils.dart';
import 'package:share_plus/share_plus.dart';

mixin CreateFixedPaymentViewModelMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // Campos del formulario
  String? title;
  String? titleHint;
  double amount = 0.0;
  DateTime startDate = DateTime.now();
  FixedPaymentFrequency frequency = FixedPaymentFrequency.monthly;
  String? description;
  String? supplier;
  double vatRate = 0.0; // 0, 0.04, 0.10, 0.21
  bool amountIsGross = true;
  bool deductible = true;
  FixedPaymentCategory category = FixedPaymentCategory.other;
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
      title:
          (title == null || title!.trim().isEmpty)
              ? (titleHint ?? '')
              : title!.trim(),
      amount: amount,
      startDate: startDate,
      frequency: frequency,
      description: description,
      supplier: supplier,
      vatRate: vatRate,
      amountIsGross: amountIsGross,
      deductible: deductible,
      category: category,
      image: proofImage,
    );
  }

  Future<void> loadDefaults(BuildContext context) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final useCases = context.read<SelfEmployedUserUseCases>();
      final res = await useCases.getUser(uid);
      res.fold((_) {}, (user) {
        setState(() {
          vatRate = user.defaultExpenseVatRate;
          amountIsGross = user.defaultExpenseAmountIsGross;
          deductible = user.defaultExpenseDeductible;
        });
      });
    } catch (_) {
      // ignore errors, keep defaults
    }
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
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
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
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text("Error al guardar el pago: $e")),
      );
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> pickImage({ImageSource source = ImageSource.camera}) async {
    final pickedFile = await picker.pickImage(source: source);
    if (!mounted) return;
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

  String _resolvedDocumentTitle() {
    final trimmedTitle = title?.trim();
    if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
      return trimmedTitle;
    }
    final trimmedHint = titleHint?.trim();
    if (trimmedHint != null && trimmedHint.isNotEmpty) {
      return trimmedHint;
    }
    return 'Pago fijo';
  }

  Future<void> selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> generateAndSharePdf() async {
    final pdf = PdfAUtils.createDocument();
    final pageTheme = await PdfAUtils.pageTheme();
    final Uint8List? imageBytes =
        proofImage != null
            ? await PdfAUtils.prepareImageBytesForPdfA(proofImage!)
            : null;

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
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
              if (imageBytes != null)
                pw.Column(
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Text('Comprobante:'),
                    pw.SizedBox(height: 8),
                    pw.Image(pw.MemoryImage(imageBytes)),
                  ],
                ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final normalized = await PdfAUtils.maybeNormalizeOnBackend(
      bytes,
      request: PdfaBackendRequest.strict(
        metadata: <String, String>{
          'title': 'Pago fijo - ${_resolvedDocumentTitle()}',
          'author': 'Gestr App',
          'subject': 'Comprobante de pago fijo',
          'keywords': 'gestr,pago_fijo',
          'frequency': frequency.name,
        },
      ),
    );
    final files = <XFile>[
      XFile.fromData(
        normalized,
        name: 'pago_fijo.pdf',
        mimeType: 'application/pdf',
      ),
    ];

    if (proofImage != null) {
      try {
        final sanitized = AeatImageSupport.sanitizeLabel(
          _resolvedDocumentTitle(),
        );
        final attachments = await AeatImageSupport.generateAttachments(
          proofImage!,
          baseName: sanitized,
        );

        files.addAll(
          attachments.map(
            (attachment) => XFile.fromData(
              attachment.bytes,
              name: attachment.filename,
              mimeType: attachment.mimeType,
            ),
          ),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudieron generar todos los formatos AEAT'),
            ),
          );
        }
      }
    }

    await SharePlus.instance.share(
      ShareParams(files: files, text: 'Aquí está el comprobante del pago fijo'),
    );
  }
}
