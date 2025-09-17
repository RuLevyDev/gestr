import 'dart:io';

import 'package:gestr/core/pdf/pdfa_sample_generator.dart';

void main(List<String> args) {
  final outputDir = Directory('samples/pdfs');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  stdout.writeln('Generating PDF/A sample documents in ${outputDir.path}');

  final descriptors = <_PdfDescriptor>[
    const _PdfDescriptor(
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
    ),
    const _PdfDescriptor(
      fileName: 'invoice_sample.pdf',
      title: 'Invoice Sample',
      author: 'Gestr App',
      docId: 'uuid-invoice',
      lines: [
        'INVOICE SUMMARY',
        'CLIENT: ACME CORP',
        'ISSUE DATE: 2024-05-30',
        'TOTAL: EUR 1,512.50',
        'STATUS: PAID',
        'NOTES: SAMPLE RECORD',
      ],
    ),
  ];

  for (final descriptor in descriptors) {
    final bytes = PdfaSampleGenerator.generate(
      title: descriptor.title,
      author: descriptor.author,
      lines: descriptor.lines,
      docId: descriptor.docId,
    );
    final file = File('${outputDir.path}/${descriptor.fileName}');
    file.writeAsBytesSync(bytes, flush: true);
  }

  stdout.writeln('Generated files:');

  for (final descriptor in descriptors) {
    final file = File('${outputDir.path}/${descriptor.fileName}');
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
  });

  final String fileName;
  final String title;
  final String author;
  final String docId;
  final List<String> lines;
}
