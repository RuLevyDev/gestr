import 'dart:convert';

import 'dart:io';

import 'package:gestr/app/invoices/application/pdf/invoice_pdf_builder.dart';

import 'package:gestr/app/invoices/application/pdf/invoice_pdf_content.dart';

import 'package:gestr/app/invoices/application/pdf/invoice_pdf_v14_builder.dart';

import 'package:gestr/core/config/compliance_constants.dart';

import 'package:gestr/core/pdf/aeat_xmp.dart';

import 'package:gestr/core/pdf/pdfa_generator.dart';

import 'package:gestr/core/pdf/pdfa_utils.dart';

import 'package:gestr/domain/entities/invoice_model.dart';

Future<void> main(List<String> args) async {
  final outputDir = Directory('samples/pdfs');

  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  stdout.writeln('Generating PDF/A sample documents in ${outputDir.path}');

  final fixedDescriptors = <_PdfDescriptor>[
    _PdfDescriptor(
      fileName: 'fixed_payment_sample.pdf',

      title: 'Fixed Payment Sample',

      author: 'Gestr App',

      docId: 'uuid-fixed',

      lines: [
        'FIXED PAYMENT SUMMARY',

        'PLAN: ALPHA',

        'START DATE: 2024-01-15',

        'AMOUNT: EUR 39.90',

        'FREQUENCY: MONTHLY',

        'STATUS: ACTIVE',
      ],

      timestamp: DateTime.utc(2024, 1, 1, 0, 0, 0),
    ),
  ];

  final invoiceSamples = <_InvoiceSample>[
    _InvoiceSample(
      fileName: 'invoice_sample.pdf',

      metadataFileName: 'invoice_sample_metadata.xmp',

      docIdSeed: 'invoice-sample',

      metadataTimestamp: DateTime.utc(2024, 5, 30, 10, 0, 0),

      content: InvoicePdfContent(
        title: 'Factura servicios Gestr mayo 2024',
        invoiceNumber: 'INV-2024-001',
        issueDate: DateTime.utc(2024, 5, 30),
        netAmount: 1250.00,
        ivaAmount: 262.50,
        status: InvoiceStatus.paid,
        issuerName: 'Gestr Labs S.L.',
        issuerTaxId: 'B12345678',
        issuerAddress: 'C/ Mayor 10, 28013 Madrid',
        receiverName: 'ACME Corp.',
        receiverTaxId: 'ESX1234567Z',
        receiverAddress: r'Av. de Europa 45, 4o B\n28922 Alcorcon, Madrid',
        concept:
            r'Consultoria y mantenimiento de plataforma Gestr.\nPeriodo: mayo 2024',
        vatRate: 21.0,
      ),
    ),
    _InvoiceSample(
      fileName: 'invoice_sample_pedido.pdf',
      metadataFileName: 'invoice_sample_pedido_metadata.xmp',
      docIdSeed: 'invoice-sample-pedido',
      metadataTimestamp: DateTime.utc(2024, 6, 1, 10, 0, 0),
      content: InvoicePdfContent(
        title: 'Factura con pedido junio 2024',
        invoiceNumber: 'INV-2024-002',
        issueDate: DateTime.utc(2024, 6, 1),
        netAmount: 25.50,
        ivaAmount: 5.36,
        status: InvoiceStatus.paid,
        issuerName: 'Gestr Labs S.L.',
        issuerTaxId: 'B12345678',
        issuerAddress: 'C/ Mayor 10, 28013 Madrid',
        receiverName: 'ACME Corp.',
        receiverTaxId: 'ESX1234567Z',
        receiverAddress: 'Av. de Europa 45, 4o B\n28922 Alcorcon, Madrid',
        concept: 'Producto A x 2.00 @ 10.00 = 20.00\nProducto B x 1.00 @ 5.50 = 5.50',
        vatRate: 21.0,
      ),
    ),
  ];

  final generatedFiles = <File>[];

  for (final descriptor in fixedDescriptors) {
    final bytes = PdfaGenerator.generate(
      title: descriptor.title,

      author: descriptor.author,

      lines: descriptor.lines,

      docId: descriptor.docId,

      homologationRef: ComplianceConstants.homologationReference,

      timestamp: descriptor.timestamp,

      softwareName: ComplianceConstants.softwareName,

      softwareVersion: ComplianceConstants.softwareVersion,
    );

    final file = File('${outputDir.path}/${descriptor.fileName}');

    file.writeAsBytesSync(bytes, flush: true);

    generatedFiles.add(file);
  }

  for (final sample in invoiceSamples) {
    final pdfBytes = await InvoicePdfBuilder.build(sample.content);

    final normalized = await PdfAUtils.maybeNormalizeOnBackend(
      pdfBytes,

      request: PdfaBackendRequest.strict(
        metadata: <String, String>{
          'title': 'Factura - ${sample.content.title}',

          'author': ComplianceConstants.softwareName,

          'status': sample.content.status.name,
        },
      ),
    );

    final pdfFile = File('${outputDir.path}/${sample.fileName}');

    pdfFile.writeAsBytesSync(normalized, flush: true);

    generatedFiles.add(pdfFile);

    final timestamp = sample.metadataTimestamp.toUtc();

    final docId = PdfaGenerator.generateDocId(
      '${sample.docIdSeed}-${timestamp.toIso8601String()}',
    );

    final metadataXmp = buildAeatXmp(
      title: 'Factura - ${sample.content.title}',

      author: ComplianceConstants.softwareName,

      docId: docId,

      homologationRef: ComplianceConstants.homologationReference,

      timestamp: timestamp,

      softwareName: ComplianceConstants.softwareName,

      softwareVersion: ComplianceConstants.softwareVersion,
    );

    final metadataFile = File('${outputDir.path}/${sample.metadataFileName}');

    metadataFile.writeAsBytesSync(utf8.encode(metadataXmp), flush: true);

    generatedFiles.add(metadataFile);

    final standardFileName = sample.fileName.replaceFirst('.pdf', '_v14.pdf');

    final pdf14Bytes = await InvoicePdfStandardBuilder.build(sample.content);

    final pdf14File = File('${outputDir.path}/$standardFileName');

    pdf14File.writeAsBytesSync(pdf14Bytes, flush: true);

    generatedFiles.add(pdf14File);
  }

  stdout.writeln('Generated files:');

  for (final file in generatedFiles) {
    if (file.existsSync()) {
      stdout.writeln(' - ${file.path} (${file.lengthSync()} bytes)');
    }
  }
}

class _PdfDescriptor {
  const _PdfDescriptor({
    required this.fileName,

    required this.title,

    required this.author,

    required this.docId,

    required this.lines,

    required this.timestamp,
  });

  final String fileName;

  final String title;

  final String author;

  final String docId;

  final List<String> lines;

  final DateTime timestamp;
}

class _InvoiceSample {
  const _InvoiceSample({
    required this.fileName,

    required this.metadataFileName,

    required this.docIdSeed,

    required this.metadataTimestamp,

    required this.content,
  });

  final String fileName;

  final String metadataFileName;

  final String docIdSeed;

  final DateTime metadataTimestamp;

  final InvoicePdfContent content;
}
