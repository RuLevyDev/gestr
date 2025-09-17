import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_event.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/domain/usecases/user/self_employed_user_usecases.dart';
import 'package:gestr/data/ocr/ocr_service.dart';
import 'package:gestr/data/repositories/ocr/ocr_repository_impl.dart';
import 'package:gestr/domain/usecases/ocr/ocr_usecases.dart';
import 'package:gestr/core/image/aeat_image_support.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:gestr/core/pdf/pdfa_utils.dart';
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
  late final OcrUseCases ocrUseCases;
  late final OcrService _ocrService;

  // User profile
  SelfEmployedUser? selfEmployedUser;

  // Controllers for advanced fields
  final TextEditingController issuerController = TextEditingController();
  final TextEditingController receiverController = TextEditingController();
  final TextEditingController conceptController = TextEditingController();
  // Controllers para importes que se actualizan por OCR
  final TextEditingController amountController = TextEditingController();
  final TextEditingController ivaController = TextEditingController();

  // Campos adicionales
  String? issuer;
  String? receiver;
  String? concept;
  String? receiverTaxId;
  String? receiverAddress;

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
    _ocrService = OcrService();
    ocrUseCases = OcrUseCases(OcrRepositoryImpl(_ocrService));
    _loadUser();
    _syncAmountControllers();
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
      _syncAmountControllers();
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
      receiverTaxId: receiverTaxId,
      receiverAddress: receiverAddress,
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
      receiverTaxId = null;
      receiverAddress = null;
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
      final file = File(pickedFile.path);
      setState(() {
        invoiceImage = file;
      });
      try {
        final data = await ocrUseCases.parseInvoice(file);
        if (data.title == null &&
            data.amount == null &&
            data.date == null &&
            data.issuer == null &&
            data.receiver == null &&
            data.concept == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo extraer información de la imagen'),
              ),
            );
          }
        }
        if (!mounted) return;
        setState(() {
          title ??= data.title;
          // Importes desde OCR
          if (data.amount != null) {
            amount = data.amount!; // base
          } else if (data.totalAmount != null && data.vatAmount != null) {
            amount = (data.totalAmount! - data.vatAmount!).clamp(
              0,
              double.infinity,
            );
          }
          if (data.vatAmount != null) {
            iva = data.vatAmount!;
          } else if (data.totalAmount != null && data.amount != null) {
            iva = (data.totalAmount! - data.amount!).clamp(0, double.infinity);
          } else if (data.totalAmount != null && data.vatRate != null) {
            final r = data.vatRate! / 100.0;
            final base = data.totalAmount! / (1 + r);
            iva = data.totalAmount! - base;
            amount = base;
          }
          _syncAmountControllers();
          if (data.date != null) {
            invoiceDate = data.date!;
          }
          if (data.issuer != null) {
            issuerController.text = data.issuer!;
            issuer = data.issuer;
          }
          if (data.receiver != null) {
            receiverController.text = data.receiver!;
            receiver = data.receiver;
          }
          if (data.concept != null && (conceptController.text.isEmpty)) {
            conceptController.text = data.concept!;
            concept = data.concept;
          }
          // Si hay ítems OCR, rellenar el concepto como listado si aún vacío
          if (data.items.isNotEmpty && conceptController.text.isEmpty) {
            final lines = [
              for (final it in data.items)
                '${it.quantity} x ${it.product} - ${it.price.toStringAsFixed(2)} €',
            ];
            final text = lines.join('\n');
            conceptController.text = text;
            concept = text;
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al procesar la imagen: $e')),
          );
        }
      }
    }
  }

  void removeImage() {
    setState(() {
      invoiceImage = null;
    });
  }

  String _resolvedInvoiceTitle() {
    final trimmedTitle = title?.trim();
    if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
      return trimmedTitle;
    }
    final formattedDate = '${invoiceDate.toLocal()}'.split(' ').first;
    return 'Factura $formattedDate';
  }

  @override
  void dispose() {
    issuerController.dispose();
    receiverController.dispose();
    conceptController.dispose();
    amountController.dispose();
    ivaController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  void _syncAmountControllers() {
    amountController.text = amount > 0 ? amount.toStringAsFixed(2) : '';
    ivaController.text = iva > 0 ? iva.toStringAsFixed(2) : '';
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
    final pdf = PdfAUtils.createDocument();
    final pageTheme = await PdfAUtils.pageTheme();
    final Uint8List? imageBytes =
        invoiceImage != null
            ? await PdfAUtils.prepareImageBytesForPdfA(invoiceImage!)
            : null;

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
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
              if (imageBytes != null)
                pw.Column(
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Text('Imagen de factura:'),
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
          'title': 'Factura - ${_resolvedInvoiceTitle()}',
          'author': 'Gestr App',
          'subject': 'Factura generada en Gestr',
          'keywords': 'gestr,factura',
          'status': status.name,
        },
      ),
    );
    final files = <XFile>[
      XFile.fromData(
        normalized,
        name: 'factura.pdf',
        mimeType: 'application/pdf',
      ),
    ];

    if (invoiceImage != null) {
      try {
        final sanitized = AeatImageSupport.sanitizeLabel(
          _resolvedInvoiceTitle(),
        );
        final attachments = await AeatImageSupport.generateAttachments(
          invoiceImage!,
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudieron generar todos los formatos AEAT'),
            ),
          );
        }
      }
    }

    await SharePlus.instance.share(
      ShareParams(files: files, text: 'Aquí está tu factura generada'),
    );
  }
}
