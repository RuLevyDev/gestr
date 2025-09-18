import 'dart:typed_data';

import 'package:gestr/app/invoices/application/pdf/invoice_pdf_content.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoicePdfStandardBuilder {
  const InvoicePdfStandardBuilder._();

  static Future<Uint8List> build(InvoicePdfContent content) async {
    final fonts = _PdfFonts(
      base: await PdfGoogleFonts.openSansRegular(),
      bold: await PdfGoogleFonts.openSansBold(),
      semiBold: await PdfGoogleFonts.openSansBold(),
    );

    final doc = pw.Document(version: PdfVersion.pdf_1_4, compress: true);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
        build: (context) => _InvoicePage(content: content, fonts: fonts),
      ),
    );

    return doc.save();
  }
}

class _PdfFonts {
  const _PdfFonts({
    required this.base,
    required this.bold,
    required this.semiBold,
  });

  final pw.Font base;
  final pw.Font bold;
  final pw.Font semiBold;
}

class _InvoicePage extends pw.StatelessWidget {
  _InvoicePage({required this.content, required this.fonts});

  final InvoicePdfContent content;
  final _PdfFonts fonts;

  final PdfColor _headingColor = PdfColor.fromInt(0xff0b1f33);
  final PdfColor _primaryText = PdfColor.fromInt(0xff1f2933);
  final PdfColor _mutedText = PdfColor.fromInt(0xff4a5568);
  final PdfColor _borderColor = PdfColor.fromInt(0xffd8dce1);
  final PdfColor _highlightBackground = PdfColor.fromInt(0xfff6f7fb);
  final PdfColor _totalBackground = PdfColor.fromInt(0xff0f4c81);
  final PdfColor _statusBackground = PdfColor.fromInt(0xffe8f1fb);
  final PdfColor _statusText = PdfColor.fromInt(0xff104c91);

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        pw.SizedBox(height: 28),
        _buildParties(),
        if (_hasConcept) ...[pw.SizedBox(height: 24), _buildConceptSection()],
        pw.SizedBox(height: 28),
        _buildAmountSection(),
        if (content.attachmentImageBytes != null) ...[
          pw.SizedBox(height: 24),
          _buildAttachmentNotice(),
        ],
        pw.Spacer(),
        _buildFooter(),
      ],
    );
  }

  bool get _hasConcept => (content.concept?.trim().isNotEmpty ?? false);

  pw.Widget _buildHeader() {
    final number = content.invoiceNumber ?? 'NO DISPONIBLE';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FACTURA',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 28,
                      letterSpacing: 2,
                      color: _headingColor,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Numero $number',
                    style: pw.TextStyle(
                      font: fonts.semiBold,
                      fontSize: 12,
                      color: _primaryText,
                    ),
                  ),
                  pw.Text(
                    'Fecha ${_formatDate(content.issueDate)}',
                    style: pw.TextStyle(
                      font: fonts.base,
                      fontSize: 11,
                      color: _mutedText,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _borderColor, width: 1),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _statusChip(content.status.labelEs.toUpperCase()),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Importe total',
                    style: pw.TextStyle(
                      font: fonts.base,
                      fontSize: 10,
                      color: _mutedText,
                    ),
                  ),
                  pw.Text(
                    _formatMoney(content.total, content.currency),
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 16,
                      color: _headingColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Container(height: 1, color: _borderColor),
      ],
    );
  }

  pw.Widget _statusChip(String label) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _statusBackground,
        borderRadius: pw.BorderRadius.circular(99),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          font: fonts.semiBold,
          fontSize: 9,
          color: _statusText,
        ),
      ),
    );
  }

  pw.Widget _buildParties() {
    final issuer = _partyDetails(
      name: content.issuerName,
      taxId: content.issuerTaxId,
      address: content.issuerAddress,
    );
    final receiver = _partyDetails(
      name: content.receiverName,
      taxId: content.receiverTaxId,
      address: content.receiverAddress,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _borderColor, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _partyColumn('EMISOR', issuer)),
          pw.SizedBox(width: 24),
          pw.Expanded(child: _partyColumn('RECEPTOR', receiver)),
        ],
      ),
    );
  }

  pw.Widget _partyColumn(String title, List<String> lines) {
    if (lines.isEmpty) {
      return pw.SizedBox.shrink();
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: fonts.semiBold,
            fontSize: 12,
            color: _headingColor,
          ),
        ),
        pw.SizedBox(height: 6),
        for (final line in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              line,
              style: pw.TextStyle(
                font: fonts.base,
                fontSize: 11,
                color: _primaryText,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildConceptSection() {
    final conceptLines = _wrapParagraph(content.concept ?? '');
    final isPedido = _isPedido(content.concept);
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        color: _highlightBackground,
        border: pw.Border.all(color: _borderColor, width: 1),
      ),
      padding: const pw.EdgeInsets.all(18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isPedido ? 'PEDIDO' : 'CONCEPTO',
            style: pw.TextStyle(
              font: fonts.semiBold,
              fontSize: 12,
              color: _headingColor,
            ),
          ),
          pw.SizedBox(height: 8),
          for (final line in conceptLines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                line,
                style: pw.TextStyle(
                  font: fonts.base,
                  fontSize: 11,
                  color: _primaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isPedido(String? concept) {
    if (concept == null) return false;
    if (concept.contains('\n')) return true;
    final lower = concept.toLowerCase();
    return lower.contains(' x ') && lower.contains('@');
  }

  pw.Widget _buildAmountSection() {
    final rows = [
      _AmountRow(
        label: 'Base imponible',
        value: _formatMoney(content.netAmount, content.currency),
      ),
      _AmountRow(
        label: _formatVatLabel(content.vatRate),
        value: _formatMoney(content.ivaAmount, content.currency),
      ),
    ];

    final total = _AmountRow(
      label: 'Total factura',
      value: _formatMoney(content.total, content.currency),
    );

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _borderColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            child: pw.Text(
              'RESUMEN ECONOMICO',
              style: pw.TextStyle(
                font: fonts.semiBold,
                fontSize: 12,
                color: _headingColor,
              ),
            ),
          ),
          pw.Divider(color: _borderColor, height: 1, thickness: 1),
          for (final row in rows)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _borderColor, width: 1),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    row.label,
                    style: pw.TextStyle(
                      font: fonts.base,
                      fontSize: 11,
                      color: _mutedText,
                    ),
                  ),
                  pw.Text(
                    row.value,
                    style: pw.TextStyle(
                      font: fonts.base,
                      fontSize: 11,
                      color: _primaryText,
                    ),
                  ),
                ],
              ),
            ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: pw.BoxDecoration(
              color: _totalBackground,
              borderRadius: const pw.BorderRadius.vertical(
                bottom: pw.Radius.circular(10),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  total.label,
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  total.value,
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAttachmentNotice() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _borderColor, width: 1),
        color: _highlightBackground,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ADJUNTOS',
            style: pw.TextStyle(
              font: fonts.semiBold,
              fontSize: 12,
              color: _headingColor,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Este documento incluye una imagen asociada disponible en la aplicacion.',
            style: pw.TextStyle(
              font: fonts.base,
              fontSize: 11,
              color: _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(height: 1, color: _borderColor),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generado automaticamente por Gestr App',
          style: pw.TextStyle(font: fonts.base, fontSize: 9, color: _mutedText),
        ),
      ],
    );
  }

  List<String> _partyDetails({String? name, String? taxId, String? address}) {
    final lines = <String>[];
    if (name != null && name.trim().isNotEmpty) {
      lines.add(name.trim());
    }
    if (taxId != null && taxId.trim().isNotEmpty) {
      lines.add('NIF: ${taxId.trim()}');
    }
    if (address != null && address.trim().isNotEmpty) {
      lines.addAll(_wrapParagraph(address.trim()));
    }
    return lines;
  }

  List<String> _wrapParagraph(String text) {
    final normalized = text.replaceAll(RegExp(r'\r\n?'), '\n');
    final segments = normalized.split('\n');
    final buffer = <String>[];
    for (final segment in segments) {
      if (segment.trim().isEmpty) {
        continue;
      }
      buffer.addAll(_wrapLine(segment.trim(), maxChars: 90));
    }
    return buffer;
  }

  List<String> _wrapLine(String text, {int maxChars = 90}) {
    if (text.length <= maxChars) {
      return <String>[text];
    }
    final words = text.split(' ');
    final lines = <String>[];
    var current = StringBuffer();
    for (final word in words) {
      if (current.isEmpty) {
        current.write(word);
        continue;
      }
      if ((current.length + word.length + 1) > maxChars) {
        lines.add(current.toString());
        current = StringBuffer(word);
      } else {
        current.write(' ');
        current.write(word);
      }
    }
    if (current.isNotEmpty) {
      lines.add(current.toString());
    }
    return lines;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  String _formatMoney(double value, String currency) {
    final amount = value.toStringAsFixed(2);
    return '$amount $currency';
  }

  String _formatVatLabel(double? vatRate) {
    if (vatRate == null) {
      return 'IVA';
    }
    var text = vatRate.abs().toStringAsFixed(2);
    while (text.contains('.') && (text.endsWith('0') || text.endsWith('.'))) {
      text = text.substring(0, text.length - 1);
    }
    return 'IVA ($text%)';
  }
}

class _AmountRow {
  const _AmountRow({required this.label, required this.value});

  final String label;
  final String value;
}
