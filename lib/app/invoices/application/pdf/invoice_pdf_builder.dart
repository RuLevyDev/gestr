import 'dart:typed_data';

import 'package:gestr/core/pdf/pdfa_utils.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

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
    pw.ThemeData? theme,
  }) async {
    final document = PdfAUtils.createDocument();
    final pageTheme = await PdfAUtils.pageTheme(theme: theme);

    final formattedDate = _formatDate(content.issueDate);
    final invoiceNumber = content.invoiceNumber?.trim();
    final issuer = _normalizeMultiline(content.issuerName);
    final receiverDetails = _buildReceiverDetails(
      content.receiverName,
      content.receiverTaxId,
      content.receiverAddress,
    );
    final concept = _normalizeMultiline(content.concept);

    final statusColors = _resolveStatusColors(content.status);
    final primaryColor = pdf.PdfColor.fromInt(0xFF009688);

    pw.Widget kv(String key, String value) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(right: 12, bottom: 6),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              key,
              style: pw.TextStyle(
                fontSize: 10,
                color: pdf.PdfColor.fromInt(0xFF727272),
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      );
    }

    pw.Widget partyBox(String title, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: pdf.PdfColor.fromInt(0xFFDDDDDD)),
          color: pdf.PdfColor.fromInt(0xFFF6F6F6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
            pw.SizedBox(height: 6),
            pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      );
    }

    String money(double value) =>
        '${value.toStringAsFixed(2)} ${content.currency}';

    pw.Widget totalsTable() {
      final rows = [
        {'label': 'Base imponible', 'value': content.netAmount, 'bold': false},
        {'label': 'IVA', 'value': content.ivaAmount, 'bold': false},
        {'label': 'Total', 'value': content.total, 'bold': true},
      ];
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: pdf.PdfColor.fromInt(0xFFDDDDDD)),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            for (int i = 0; i < rows.length; i++)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: pw.BoxDecoration(
                  color:
                      i == rows.length - 1
                          ? pdf.PdfColor.fromInt(0xFFE0F2F1)
                          : pdf.PdfColors.white,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      rows[i]['label'] as String,
                      style: pw.TextStyle(
                        fontWeight:
                            (rows[i]['bold'] as bool)
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                        fontSize: (rows[i]['bold'] as bool) ? 12 : 11,
                      ),
                    ),
                    pw.Text(
                      money(rows[i]['value'] as double),
                      style: pw.TextStyle(
                        fontWeight:
                            (rows[i]['bold'] as bool)
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                        fontSize: (rows[i]['bold'] as bool) ? 12 : 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    document.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) {
          final partyWidgets = <pw.Widget>[];
          if (issuer != null && issuer.isNotEmpty) {
            partyWidgets.add(partyBox('Emisor', issuer));
          }
          if (receiverDetails.isNotEmpty) {
            partyWidgets.add(partyBox('Receptor', receiverDetails));
          }

          return pw.Container(
            color: pdf.PdfColor.fromInt(0xFFF3F4F6),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Center(
              child: pw.ConstrainedBox(
                constraints: pw.BoxConstraints(
                  maxWidth: context.page.pageFormat.availableWidth - 48,
                ),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: pdf.PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(18),
                    border: pw.Border.all(
                      color: pdf.PdfColor.fromInt(0xFFE0E0E0),
                    ),
                  ),
                  padding: const pw.EdgeInsets.all(28),
                  child: pw.Column(
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
                                    fontSize: 22,
                                    fontWeight: pw.FontWeight.bold,
                                    letterSpacing: 3,
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  content.title,
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: pdf.PdfColor.fromInt(0xFF424242),
                                  ),
                                ),
                                pw.SizedBox(height: 10),
                                pw.Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    kv(
                                      'N.º',
                                      invoiceNumber?.isNotEmpty == true
                                          ? invoiceNumber!
                                          : '—',
                                    ),
                                    kv('Fecha', formattedDate),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: statusColors.background,
                                  borderRadius: pw.BorderRadius.circular(999),
                                ),
                                child: pw.Text(
                                  content.status.labelEs.toUpperCase(),
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: statusColors.foreground,
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 18),
                              pw.Container(
                                width: 58,
                                height: 58,
                                decoration: pw.BoxDecoration(
                                  color: pdf.PdfColor.fromInt(0xFFE0F2F1),
                                  borderRadius: pw.BorderRadius.circular(14),
                                ),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'Factura',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 18),
                      pw.Divider(color: pdf.PdfColor.fromInt(0xFFDDDDDD)),
                      pw.SizedBox(height: 18),
                      if (partyWidgets.isNotEmpty)
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (partyWidgets.length == 1) ...[
                              partyWidgets.first,
                            ] else ...[
                              pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Expanded(child: partyWidgets[0]),
                                  pw.SizedBox(width: 16),
                                  pw.Expanded(child: partyWidgets[1]),
                                ],
                              ),
                            ],
                          ],
                        ),
                      if (partyWidgets.isNotEmpty) pw.SizedBox(height: 20),
                      if (concept != null && concept.isNotEmpty) ...[
                        pw.Text(
                          'Concepto',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: pdf.PdfColor.fromInt(0xFFE8F5E9),
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Text(
                            concept,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.SizedBox(height: 24),
                      ],
                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.ConstrainedBox(
                          constraints: const pw.BoxConstraints(maxWidth: 320),
                          child: totalsTable(),
                        ),
                      ),
                      if (content.attachmentImageBytes != null) ...[
                        pw.SizedBox(height: 18),
                        pw.Divider(color: pdf.PdfColor.fromInt(0xFFDDDDDD)),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'Adjuntos',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          decoration: pw.BoxDecoration(
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(
                              color: pdf.PdfColor.fromInt(0xFFDDDDDD),
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(10),
                              color: pdf.PdfColors.white,
                            ),
                            child: pw.Image(
                              pw.MemoryImage(content.attachmentImageBytes!),
                              height: 180,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return document.save();
  }

  static _StatusColors _resolveStatusColors(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return _StatusColors(
          background: pdf.PdfColor.fromInt(0xFFE8F5E9),
          foreground: pdf.PdfColor.fromInt(0xFF2E7D32),
        );
      case InvoiceStatus.pending:
        return _StatusColors(
          background: pdf.PdfColor.fromInt(0xFFFFF3E0),
          foreground: pdf.PdfColor.fromInt(0xFFEF6C00),
        );
      case InvoiceStatus.sent:
        return _StatusColors(
          background: pdf.PdfColor.fromInt(0xFFE3F2FD),
          foreground: pdf.PdfColor.fromInt(0xFF1565C0),
        );
      case InvoiceStatus.overdue:
        return _StatusColors(
          background: pdf.PdfColor.fromInt(0xFFFFEBEE),
          foreground: pdf.PdfColor.fromInt(0xFFC62828),
        );
      case InvoiceStatus.paidByMe:
        return _StatusColors(
          background: pdf.PdfColor.fromInt(0xFFF3E5F5),
          foreground: pdf.PdfColor.fromInt(0xFF6A1B9A),
        );
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  static String? _normalizeMultiline(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final lines = trimmed
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    return lines.join('\n');
  }

  static String _buildReceiverDetails(
    String? name,
    String? taxId,
    String? address,
  ) {
    final buffer = <String>[];
    final normalizedName = _normalizeMultiline(name);
    if (normalizedName != null && normalizedName.isNotEmpty) {
      buffer.add(normalizedName);
    }
    final normalizedTaxId = taxId?.trim();
    if (normalizedTaxId != null && normalizedTaxId.isNotEmpty) {
      buffer.add('NIF: $normalizedTaxId');
    }
    final normalizedAddress = _normalizeMultiline(address);
    if (normalizedAddress != null && normalizedAddress.isNotEmpty) {
      buffer.add(normalizedAddress);
    }
    return buffer.join('\n');
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});

  final pdf.PdfColor background;
  final pdf.PdfColor foreground;
}
