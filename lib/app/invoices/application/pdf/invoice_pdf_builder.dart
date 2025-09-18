import 'dart:typed_data';

import 'package:gestr/core/config/compliance_constants.dart';
import 'package:gestr/core/pdf/pdfa_generator.dart';
import 'package:gestr/core/pdf/pixel_font.dart';
import 'package:gestr/domain/entities/invoice_model.dart';

class InvoicePdfContent {
  const InvoicePdfContent({
    required this.title,
    required this.issueDate,
    required this.netAmount,
    required this.ivaAmount,
    required this.status,
    this.invoiceNumber,
    this.issuerName,
    this.receiverName,
    this.receiverTaxId,
    this.receiverAddress,
    this.concept,
    this.currency = 'EUR',
    this.attachmentImageBytes,
  });

  final String title;
  final DateTime issueDate;
  final double netAmount;
  final double ivaAmount;
  final InvoiceStatus status;
  final String? invoiceNumber;
  final String? issuerName;
  final String? receiverName;
  final String? receiverTaxId;
  final String? receiverAddress;
  final String? concept;
  final String currency;
  final Uint8List? attachmentImageBytes;

  double get total => netAmount + ivaAmount;
}

class InvoicePdfBuilder {
  const InvoicePdfBuilder._();

  static Future<Uint8List> build(
    InvoicePdfContent content, {
    Object? theme,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final docId = PdfaGenerator.generateDocId(
      '${content.invoiceNumber ?? content.title}-${timestamp.toIso8601String()}',
    );
    final lines = _buildLines(content);

    return PdfaGenerator.generate(
      title: content.title,
      author: ComplianceConstants.softwareName,
      docId: docId,
      homologationRef: ComplianceConstants.homologationReference,
      timestamp: timestamp,
      softwareName: ComplianceConstants.softwareName,
      softwareVersion: ComplianceConstants.softwareVersion,
      lines: lines,
    );
  }
}

const double _kPdfaFontSize = 12.0;
const double _kMaxTextWidth = 36 * 12.0;
const String _sectionSeparator = '------------------------------';

List<String> _buildLines(InvoicePdfContent content) {
  final lines = <String>[];

  lines.add('FACTURA');
  final sanitizedTitle = PdfaGenerator.sanitizeLine(content.title);
  if (sanitizedTitle.isNotEmpty) {
    lines.add(sanitizedTitle);
  }

  lines.add(_sectionSeparator);
  lines.add(PdfaGenerator.sanitizeLine('DATOS GENERALES'));
  lines.add(_composeKeyValue('ESTADO', content.status.labelEs));
  lines.add(
    _composeKeyValue('NUMERO', content.invoiceNumber ?? 'No disponible'),
  );
  lines.add(_composeKeyValue('FECHA', _formatDate(content.issueDate)));
  lines.add(_composeKeyValue('MONEDA', content.currency));
  lines.add('');

  lines.add(_sectionSeparator);
  lines.add(PdfaGenerator.sanitizeLine('RESUMEN IMPORTE'));
  lines.add(
    _composeKeyValue(
      'BASE IMPONIBLE',
      _formatMoney(content.netAmount, content.currency),
    ),
  );
  lines.add(
    _composeKeyValue('IVA', _formatMoney(content.ivaAmount, content.currency)),
  );
  lines.add(
    _composeKeyValue(
      'TOTAL A COBRAR',
      _formatMoney(content.total, content.currency),
    ),
  );
  lines.add('');

  final issuerLines = _wrapMultiline(content.issuerName);
  if (issuerLines.isNotEmpty) {
    lines.add(_sectionSeparator);
    lines.add(PdfaGenerator.sanitizeLine('DATOS EMISOR'));
    lines.addAll(issuerLines);
    lines.add('');
  }

  final receiverLines = _receiverDetails(
    content.receiverName,
    content.receiverTaxId,
    content.receiverAddress,
  );
  if (receiverLines.isNotEmpty) {
    lines.add(_sectionSeparator);
    lines.add(PdfaGenerator.sanitizeLine('DATOS RECEPTOR'));
    lines.addAll(receiverLines);
    lines.add('');
  }

  final conceptLines = _wrapParagraph(content.concept);
  if (conceptLines.isNotEmpty) {
    lines.add(_sectionSeparator);
    lines.add(PdfaGenerator.sanitizeLine('CONCEPTO'));
    lines.addAll(conceptLines);
    lines.add('');
  }

  if (content.attachmentImageBytes != null) {
    lines.add(_sectionSeparator);
    lines.add(PdfaGenerator.sanitizeLine('ADJUNTOS'));
    lines.add(PdfaGenerator.sanitizeLine('IMAGEN DISPONIBLE EN LA APLICACION'));
    lines.add('');
  }

  lines.add(_sectionSeparator);
  lines.add(PdfaGenerator.sanitizeLine('GENERADO POR GESTR APP'));

  return lines;
}

String _composeKeyValue(String key, String value) {
  final sanitizedKey = PdfaGenerator.sanitizeLine(key);
  final sanitizedValue = PdfaGenerator.sanitizeLine(value);
  if (sanitizedKey.isEmpty) {
    return sanitizedValue;
  }
  if (sanitizedValue.isEmpty) {
    return sanitizedKey;
  }
  return '$sanitizedKey: $sanitizedValue';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day-$month-$year';
}

String _formatMoney(double value, String currency) {
  final sanitizedCurrency = PdfaGenerator.sanitizeLine(currency);
  final amount = value.toStringAsFixed(2);
  return sanitizedCurrency.isEmpty ? amount : '$amount $sanitizedCurrency';
}

List<String> _wrapParagraph(String? text) {
  if (text == null || text.trim().isEmpty) {
    return <String>[];
  }
  return PixelFont.wrap(
    text,
    fontSize: _kPdfaFontSize,
    maxWidth: _kMaxTextWidth,
  );
}

List<String> _wrapMultiline(String? text) {
  if (text == null || text.trim().isEmpty) {
    return <String>[];
  }
  final segments = text.split('\n');
  final lines = <String>[];
  for (final segment in segments) {
    if (segment.trim().isEmpty) {
      continue;
    }
    lines.addAll(
      PixelFont.wrap(
        segment,
        fontSize: _kPdfaFontSize,
        maxWidth: _kMaxTextWidth,
      ),
    );
  }
  return lines;
}

List<String> _receiverDetails(String? name, String? taxId, String? address) {
  final buffer = <String>[];
  if (name != null && name.trim().isNotEmpty) {
    buffer.addAll(
      PixelFont.wrap(name, fontSize: _kPdfaFontSize, maxWidth: _kMaxTextWidth),
    );
  }
  if (taxId != null && taxId.trim().isNotEmpty) {
    buffer.add(_composeKeyValue('NIF', taxId));
  }
  if (address != null && address.trim().isNotEmpty) {
    buffer.addAll(
      PixelFont.wrap(
        address,
        fontSize: _kPdfaFontSize,
        maxWidth: _kMaxTextWidth,
      ),
    );
  }
  return buffer;
}
