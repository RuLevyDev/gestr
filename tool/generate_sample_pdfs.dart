import 'dart:io';
import 'dart:typed_data';

import 'package:gestr/core/pdf/pdfa_utils.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

Future<void> main(List<String> args) async {
  final outputDir = Directory('samples/pdfs');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  stdout.writeln('Generating PDF/A sample documents in ${outputDir.path}');

  final sampleImageBytes = await _buildTransparentSampleImageBytes();

  await _generateFixedPaymentPdf(outputDir, sampleImageBytes);
  await _generateInvoicePdf(outputDir, sampleImageBytes);

  stdout.writeln('Generated files:');
  for (final entity in outputDir.listSync().whereType<File>()) {
    stdout.writeln(' - ${entity.path} (${entity.statSync().size} bytes)');
  }
}

Future<void> _generateFixedPaymentPdf(
  Directory outputDir,
  Uint8List? imageBytes,
) async {
  final pdf = PdfAUtils.createDocument();
  final theme = await PdfAUtils.pageTheme();

  pdf.addPage(
    pw.Page(
      pageTheme: theme,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Pago Fijo', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 12),
            pw.Text('Título: Suscripción software'),
            pw.Text('Fecha de inicio: 2024-01-15'),
            pw.Text('Importe: €39.90'),
            pw.Text('Frecuencia: monthly'),
            pw.Text('Descripción: Licencia mensual para herramienta CRM'),
            if (imageBytes != null)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 20),
                  pw.Text('Comprobante:'),
                  pw.SizedBox(height: 8),
                  pw.Image(pw.MemoryImage(imageBytes), width: 180),
                ],
              ),
          ],
        );
      },
    ),
  );

  final normalized = await PdfAUtils.maybeNormalizeOnBackend(
    await pdf.save(),
    request: PdfaBackendRequest.strict(
      metadata: const <String, String>{
        'title': 'Pago fijo - Suscripción software',
        'author': 'Gestr App',
        'subject': 'Comprobante de pago fijo (muestra)',
        'keywords': 'gestr,pago_fijo,sample',
        'frequency': 'monthly',
      },
    ),
  );

  final file = File('${outputDir.path}/fixed_payment_sample.pdf');
  await file.writeAsBytes(normalized, flush: true);
}

Future<void> _generateInvoicePdf(
  Directory outputDir,
  Uint8List? imageBytes,
) async {
  final pdf = PdfAUtils.createDocument();
  final theme = await PdfAUtils.pageTheme();

  pdf.addPage(
    pw.Page(
      pageTheme: theme,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Factura', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 12),
            pw.Text('Título: Proyecto web corporativo'),
            pw.Text('Fecha: 2024-05-30'),
            pw.Text('Importe neto: €1,250.00'),
            pw.Text('IVA: €262.50'),
            pw.Text('Total: €1,512.50'),
            pw.Text('Estado: paid'),
            pw.Text('Cliente: Ejemplo S.L.'),
            pw.Text('Concepto: Desarrollo e integración CMS'),
            if (imageBytes != null)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 20),
                  pw.Text('Imagen de factura:'),
                  pw.SizedBox(height: 8),
                  pw.Image(pw.MemoryImage(imageBytes), width: 180),
                ],
              ),
          ],
        );
      },
    ),
  );

  final normalized = await PdfAUtils.maybeNormalizeOnBackend(
    await pdf.save(),
    request: PdfaBackendRequest.strict(
      metadata: const <String, String>{
        'title': 'Factura - Proyecto web corporativo',
        'author': 'Gestr App',
        'subject': 'Factura de ejemplo generada desde script local',
        'keywords': 'gestr,factura,sample',
        'status': 'paid',
      },
    ),
  );

  final file = File('${outputDir.path}/invoice_sample.pdf');
  await file.writeAsBytes(normalized, flush: true);
}

Future<Uint8List?> _buildTransparentSampleImageBytes() async {
  final tempDir = await Directory.systemTemp.createTemp('gestr-pdfa-sample');
  try {
    final file = File('${tempDir.path}/transparent.png');
    final transparent = img.Image(width: 160, height: 120);
    img.fill(transparent, color: img.ColorRgba8(0, 0, 0, 0));
    img.drawRect(
      transparent,
      x1: 0,
      y1: 0,
      x2: transparent.width - 1,
      y2: transparent.height ~/ 2,
      color: img.ColorRgba8(255, 99, 71, 120),
    );
    img.drawRect(
      transparent,
      x1: 0,
      y1: transparent.height ~/ 2,
      x2: transparent.width - 1,
      y2: transparent.height - 1,
      color: img.ColorRgba8(30, 144, 255, 180),
    );
    final pngBytes = img.encodePng(transparent);
    await file.writeAsBytes(pngBytes, flush: true);
    return await PdfAUtils.prepareImageBytesForPdfA(file);
  } catch (e) {
    stderr.writeln('Could not generate transparent sample image: $e');
    return null;
  } finally {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // ignore cleanup failure
    }
  }
}
