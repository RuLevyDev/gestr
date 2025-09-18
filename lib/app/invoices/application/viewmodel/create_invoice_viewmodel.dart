import 'dart:async';
import 'dart:convert';
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
import 'package:gestr/domain/entities/client.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:gestr/app/relationships/clients/application/view/create_client_sheet.dart';
import 'package:gestr/app/relationships/suppliers/application/view/create_supplier_sheet.dart';
import 'package:gestr/domain/usecases/client/client_usecases.dart';
import 'package:gestr/domain/usecases/supplier/supplier_usecases.dart';
import 'package:gestr/domain/usecases/user/self_employed_user_usecases.dart';
import 'package:gestr/data/ocr/ocr_service.dart';
import 'package:gestr/data/repositories/ocr/ocr_repository_impl.dart';
import 'package:gestr/domain/usecases/ocr/ocr_usecases.dart';
import 'package:gestr/core/config/compliance_constants.dart';
import 'package:gestr/core/image/aeat_image_support.dart';
import 'package:gestr/app/invoices/application/pdf/invoice_pdf_content.dart';
import 'package:gestr/core/pdf/aeat_xmp.dart';
import 'package:gestr/core/pdf/pdfa_generator.dart';

// import 'package:pdf/widgets.dart' as pw;
import 'package:gestr/core/pdf/pdfa_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gestr/app/invoices/application/pdf/invoice_pdf_v14_builder.dart';

// import 'package:printing/printing.dart';

enum InvoiceDirection { issued, received }

mixin CreateInvoiceViewModelMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // Campos del formulario
  String? title;
  DateTime invoiceDate = DateTime.now();
  double amount = 0.0;
  double iva = 0.0;
  double vatRate = 21.0; // porcentaje (0-100)
  bool isAmountIncludingIva = false;
  bool showAdvancedFields = false;
  InvoiceStatus status = InvoiceStatus.pending;
  File? invoiceImage;
  final ImagePicker picker = ImagePicker();
  late final OcrUseCases ocrUseCases;
  late final OcrService _ocrService;

  // User profile
  SelfEmployedUser? selfEmployedUser;
  InvoiceDirection direction = InvoiceDirection.issued;

  // pw.ThemeData? _invoicePdfTheme;

  // Controllers for advanced fields
  final TextEditingController issuerController = TextEditingController();
  final TextEditingController receiverController = TextEditingController();
  final TextEditingController conceptController = TextEditingController();
  final TextEditingController invoiceNumberController = TextEditingController();
  final TextEditingController receiverTaxIdController = TextEditingController();
  final TextEditingController receiverAddressController =
      TextEditingController();
  final TextEditingController issuerTaxIdController = TextEditingController();
  final TextEditingController issuerAddressController = TextEditingController();
  // Controllers para importes que se actualizan por OCR
  final TextEditingController amountController = TextEditingController();
  final TextEditingController ivaController = TextEditingController();

  // Campos adicionales
  String? issuer;
  String? receiver;
  String? concept;
  String? invoiceNumber;
  String? issuerTaxId;
  String? issuerAddress;
  String? receiverTaxId;
  String? receiverAddress;

  // Contrapartidas
  Timer? _counterpartyDebounce;
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  ClientUseCases? _clientUseCasesRef;
  SupplierUseCases? _supplierUseCasesRef;

  List<Client> get filteredClients => _filteredClients;
  List<Supplier> get filteredSuppliers => _filteredSuppliers;

  // Getters
  double get total => amount + iva;

  // ValidaciÃ³n y cÃ¡lculo
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

  void setDirection(InvoiceDirection target) {
    if (direction == target) return;
    setState(() {
      direction = target;
      _filteredClients = [];
      _filteredSuppliers = [];
      _applySelfDataInternal();
    });
  }

  void _applySelfDataInternal() {
    if (selfEmployedUser == null) return;
    final me = selfEmployedUser!;
    if (direction == InvoiceDirection.issued) {
      issuer = me.fullName;
      issuerController.text = me.fullName;
      issuerTaxId = me.dni;
      issuerTaxIdController.text = me.dni;
      issuerAddress = me.address;
      issuerAddressController.text = me.address;
      // Clear counterparty (receiver)
      receiver = null;
      receiverController.clear();
      receiverTaxId = null;
      receiverTaxIdController.clear();
      receiverAddress = null;
      receiverAddressController.clear();
    } else {
      receiver = me.fullName;
      receiverController.text = me.fullName;
      receiverTaxId = me.dni;
      receiverTaxIdController.text = me.dni;
      receiverAddress = me.address;
      receiverAddressController.text = me.address;
      // Clear counterparty (issuer)
      issuer = null;
      issuerController.clear();
      issuerTaxId = null;
      issuerTaxIdController.clear();
      issuerAddress = null;
      issuerAddressController.clear();
    }
  }

  Future<void> _loadUser() async {
    final result = await context.read<SelfEmployedUserUseCases>().getUser(
      userId,
    );
    result.fold((_) {}, (user) {
      setState(() {
        selfEmployedUser = user;
        // Usa el IVA por defecto del perfil si existe (0.0-0.21)
        try {
          final defRate = user.defaultExpenseVatRate;
          if (defRate >= 0 && defRate <= 1) {
            vatRate = (defRate * 100).clamp(0, 100);
          }
        } catch (_) {}
        _applySelfDataInternal();
      });
    });
  }

  void updateIva() => _recalcFromControllers();

  void _recalcFromControllers() {
    final rate = (vatRate.clamp(0, 100)) / 100.0;
    // Leer importe del controlador (puede representar base o total segun el switch)
    final rawAmount = amountController.text.trim().replaceAll(',', '.');
    final input = double.tryParse(rawAmount) ?? 0.0;
    if (isAmountIncludingIva) {
      final gross = input;
      final net = rate > 0 ? (gross / (1 + rate)) : gross;
      amount = net;
      iva = (gross - net).clamp(0, double.infinity);
      // Mantener el campo de importe mostrando lo que escribe el usuario (total)
      // Solo sincronizamos el campo IVA para que muestre el calculado en modo lectura.
      ivaController.text = iva > 0 ? iva.toStringAsFixed(2) : '';
    } else {
      // Modo base imponible: amount es el valor del campo y el IVA se toma del campo IVA
      amount = input;
      final rawIva = ivaController.text.trim().replaceAll(',', '.');
      iva = double.tryParse(rawIva) ?? 0.0;
    }
  }

  // Recalcula amount/iva desde líneas de pedido (qty, price)
  void syncAmountFromItemTuples(List<MapEntry<double, double>> items) {
    double base = 0.0;
    for (final it in items) {
      base += (it.key * it.value);
    }
    final rate = (vatRate.clamp(0, 100)) / 100.0;
    if (isAmountIncludingIva) {
      amount = base;
      iva = (base * rate).clamp(0, double.infinity);
    } else {
      amount = base;
    }
    _syncAmountControllers();
  }

  // Carga de datos
  Future<void> loadClients(ClientUseCases useCases) async {
    _clientUseCasesRef = useCases;
    final list = await useCases.fetch(userId);
    if (!mounted) return;
    setState(() {
      _clients = list;
    });
  }

  Future<void> loadSuppliers(SupplierUseCases useCases) async {
    _supplierUseCasesRef = useCases;
    final list = await useCases.fetch(userId);
    if (!mounted) return;
    setState(() {
      _suppliers = list;
    });
  }

  // Inicializa los usecases desde el contexto y carga datos
  void initPartnersFromContext() {
    _clientUseCasesRef ??= context.read<ClientUseCases>();
    _supplierUseCasesRef ??= context.read<SupplierUseCases>();
    unawaited(loadClients(_clientUseCasesRef!));
    unawaited(loadSuppliers(_supplierUseCasesRef!));
  }

  // Handlers de contrapartida (cliente/proveedor)
  void onClientChanged(String value) {
    _counterpartyDebounce?.cancel();
    _counterpartyDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final q = value.toLowerCase();
      setState(() {
        receiver = value;
        receiverTaxId = null;
        receiverAddress = null;
        receiverTaxIdController.clear();
        receiverAddressController.clear();
        _filteredClients =
            _clients.where((c) => c.name.toLowerCase().contains(q)).toList();
      });
    });
  }

  void selectClient(Client client) {
    setState(() {
      receiverController.text = client.name;
      receiver = client.name;
      receiverTaxId = client.taxId;
      receiverAddress = client.fiscalAddress;
      receiverTaxIdController.text = client.taxId ?? '';
      receiverAddressController.text = client.fiscalAddress ?? '';
      _filteredClients = [];
    });
  }

  Future<void> onClientSubmitted(String value) async {
    final match = _clients.firstWhere(
      (c) => c.name.toLowerCase() == value.toLowerCase(),
      orElse: () => const Client(name: ''),
    );
    if (match.id != null && match.name.isNotEmpty) {
      selectClient(match);
      return;
    }

    final should = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cliente no encontrado'),
            content: Text('Deseas registrar "$value" como nuevo cliente?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Si'),
              ),
            ],
          ),
    );
    if (!mounted) return;

    if (should == true) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => CreateClientSheet(initialName: value),
      );
      final useCases = _clientUseCasesRef;
      if (useCases != null) {
        await loadClients(useCases);
        final created = _clients.firstWhere(
          (c) => c.name.toLowerCase() == value.toLowerCase(),
          orElse: () => const Client(name: ''),
        );
        if (created.id != null && created.name.isNotEmpty) {
          selectClient(created);
          return;
        }
      }
    }

    setState(() {
      receiver = value;
      receiverTaxId = null;
      receiverAddress = null;
      receiverTaxIdController.clear();
      receiverAddressController.clear();
      _filteredClients = [];
    });
  }

  void onSupplierChanged(String value) {
    _counterpartyDebounce?.cancel();
    _counterpartyDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final query = value.toLowerCase();
      setState(() {
        issuer = value;
        issuerTaxId = null;
        issuerAddress = null;
        issuerTaxIdController.clear();
        issuerAddressController.clear();
        _filteredSuppliers =
            _suppliers
                .where((s) => s.name.toLowerCase().contains(query))
                .toList();
      });
    });
  }

  void selectSupplier(Supplier supplier) {
    setState(() {
      issuerController.text = supplier.name;
      issuer = supplier.name;
      issuerTaxId = supplier.taxId;
      issuerAddress = supplier.fiscalAddress;
      issuerTaxIdController.text = supplier.taxId ?? '';
      issuerAddressController.text = supplier.fiscalAddress ?? '';
      _filteredSuppliers = [];
    });
  }

  Future<void> onSupplierSubmitted(String value) async {
    final match = _suppliers.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => const Supplier(name: ''),
    );
    if (match.id != null && match.name.isNotEmpty) {
      selectSupplier(match);
      return;
    }

    final should = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Proveedor no encontrado'),
            content: Text('Deseas registrar "$value" como nuevo proveedor?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Si'),
              ),
            ],
          ),
    );
    if (!mounted) return;

    if (should == true) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => CreateSupplierSheet(initialName: value),
      );
      final useCases = _supplierUseCasesRef;
      if (useCases != null) {
        await loadSuppliers(useCases);
        final created = _suppliers.firstWhere(
          (s) => s.name.toLowerCase() == value.toLowerCase(),
          orElse: () => const Supplier(name: ''),
        );
        if (created.id != null && created.name.isNotEmpty) {
          selectSupplier(created);
          return;
        }
      }
    }

    setState(() {
      issuer = value;
      issuerTaxId = null;
      issuerAddress = null;
      issuerTaxIdController.clear();
      issuerAddressController.clear();
      _filteredSuppliers = [];
    });
  }

  String? normalizeText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // ConversiÃ³n a entidad Invoice
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
      invoiceNumber = null;
      receiverTaxId = null;
      receiverAddress = null;
      issuerTaxId = null;
      issuerAddress = null;
      issuerController.clear();
      receiverController.clear();
      conceptController.clear();
      invoiceNumberController.clear();
      issuerTaxIdController.clear();
      issuerAddressController.clear();
      receiverTaxIdController.clear();
      receiverAddressController.clear();
      invoiceDate = DateTime.now();
    });
  }

  // SelecciÃ³n de imagen
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
                content: Text('No se pudo extraer informaciÃ³n de la imagen'),
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
          // Si hay Ã­tems OCR, rellenar el concepto como listado si aÃºn vacÃ­o
          if (data.items.isNotEmpty && conceptController.text.isEmpty) {
            final lines = [
              for (final it in data.items)
                '${it.quantity} x ${it.product} - ${it.price.toStringAsFixed(2)} ',
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
    _counterpartyDebounce?.cancel();
    issuerController.dispose();
    receiverController.dispose();
    conceptController.dispose();
    invoiceNumberController.dispose();
    receiverTaxIdController.dispose();
    receiverAddressController.dispose();
    issuerTaxIdController.dispose();
    issuerAddressController.dispose();
    amountController.dispose();
    ivaController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  void _syncAmountControllers() {
    amountController.text = amount > 0 ? amount.toStringAsFixed(2) : '';
    ivaController.text = iva > 0 ? iva.toStringAsFixed(2) : '';
  }

  // SelecciÃ³n de fecha
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

  // Future<pw.ThemeData?> _ensureInvoicePdfTheme() async {
  //   if (_invoicePdfTheme != null) {
  //     return _invoicePdfTheme;
  //   }

  //   try {
  //     final base = await PdfGoogleFonts.openSansRegular();
  //     final bold = await PdfGoogleFonts.openSansBold();
  //     final italic = await PdfGoogleFonts.openSansItalic();
  //     final boldItalic = await PdfGoogleFonts.openSansBoldItalic();
  //     _invoicePdfTheme = pw.ThemeData.withFont(
  //       base: base,
  //       bold: bold,
  //       italic: italic,
  //       boldItalic: boldItalic,
  //     );
  //   } catch (_) {
  //     // Ignore and rely on the default Helvetica theme when fonts cannot be loaded.
  //   }

  //   return _invoicePdfTheme;
  // }

  // GeneraciÃ³n y comparticiÃ³n de PDF
  Future<void> generateAndSharePdf() async {
    final Uint8List? imageBytes =
        invoiceImage != null
            ? await PdfAUtils.prepareImageBytesForPdfA(invoiceImage!)
            : null;

    // final theme = await _ensureInvoicePdfTheme();

    final resolvedTitle = _resolvedInvoiceTitle();
    final trimmedIssuer = issuer?.trim();
    final trimmedReceiver = receiver?.trim();
    final trimmedConcept = concept?.trim();
    final trimmedReceiverTaxId = receiverTaxId?.trim();
    final trimmedReceiverAddress = receiverAddress?.trim();

    final pdfBytes = await InvoicePdfStandardBuilder.build(
      InvoicePdfContent(
        title: resolvedTitle,
        invoiceNumber: invoiceNumber?.trim(),
        issueDate: invoiceDate,
        netAmount: amount,
        ivaAmount: iva,
        status: status,
        issuerName: trimmedIssuer,
        issuerTaxId: issuerTaxId?.trim(),
        issuerAddress: issuerAddress?.trim(),
        receiverName: trimmedReceiver,
        receiverTaxId: trimmedReceiverTaxId,
        receiverAddress: trimmedReceiverAddress,
        concept: trimmedConcept,
        currency: 'EUR',
        attachmentImageBytes: imageBytes,
      ),
    );

    final normalized = await PdfAUtils.maybeNormalizeOnBackend(
      pdfBytes,
      request: PdfaBackendRequest.strict(
        metadata: <String, String>{
          'title': 'Factura - $resolvedTitle',
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

    final sanitized = AeatImageSupport.sanitizeLabel(resolvedTitle);
    final metadataTimestamp = DateTime.now().toUtc();
    final metadataDocId = PdfaGenerator.generateDocId(
      '$resolvedTitle-${metadataTimestamp.toIso8601String()}',
    );
    final metadataXmp = buildAeatXmp(
      title: 'Factura - $resolvedTitle',
      author: ComplianceConstants.softwareName,
      docId: metadataDocId,
      homologationRef: ComplianceConstants.homologationReference,
      timestamp: metadataTimestamp,
      softwareName: ComplianceConstants.softwareName,
      softwareVersion: ComplianceConstants.softwareVersion,
    );

    files.add(
      XFile.fromData(
        utf8.encode(metadataXmp),
        name: '${sanitized}_metadata.xmp',
        mimeType: 'application/rdf+xml',
      ),
    );

    if (invoiceImage != null) {
      try {
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
      ShareParams(files: files, text: 'AquÃ­ estÃ¡ tu factura generada'),
    );
  }
}
