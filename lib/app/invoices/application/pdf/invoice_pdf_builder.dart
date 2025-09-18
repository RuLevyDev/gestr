import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:gestr/core/config/compliance_constants.dart';
import 'package:gestr/core/pdf/aeat_xmp.dart';
import 'invoice_pdf_content.dart';
import 'package:gestr/core/pdf/pdf_timestamp_utils.dart';
import 'package:gestr/core/pdf/pdfa_document_builder.dart';
import 'package:gestr/core/pdf/pdfa_generator.dart';
import 'package:gestr/core/pdf/pixel_font.dart';
import 'package:gestr/domain/entities/invoice_model.dart';

class InvoicePdfBuilder {
  const InvoicePdfBuilder._();

  static Future<Uint8List> build(
    InvoicePdfContent content, {
    Object? theme,
  }) async {
    final timestamp = normalizeToSecondPrecisionUtc(DateTime.now());
    final docId = PdfaGenerator.generateDocId(
      '${content.invoiceNumber ?? content.title}-${timestamp.toIso8601String()}',
    );

    final layout = _buildLayout(content);
    PixelFont.ensureCoverage(layout.coverageStrings);

    final builder = PdfaDocumentBuilder();

    final literalTitle = _escapeLiteral(
      content.title.isEmpty ? 'FACTURA' : content.title,
    );
    final literalAuthor = _escapeLiteral(ComplianceConstants.softwareName);
    final literalProducer = _escapeLiteral(ComplianceConstants.softwareName);
    final pdfDate = formatPdfDate(timestamp);

    final infoId = builder.addObject(
      '<< /Title ($literalTitle) /Author ($literalAuthor) '
      '/Producer ($literalProducer) '
      '/CreationDate ($pdfDate) /ModDate ($pdfDate) >>',
    );

    final contentString = _buildContentStream(layout);
    final contentBytes = ascii.encode(contentString);
    final contentId = builder.addStream(
      '<< /Length ${contentBytes.length} >>',
      contentBytes,
    );

    final colorSpaceId = builder.addObject(
      '[ /CalRGB << /WhitePoint [0.9505 1.0 1.0890] /Gamma [2.2 2.2 2.2] >> ]',
    );
    final resourcesId = builder.addObject(
      '<< /ColorSpace << /CS0 $colorSpaceId 0 R >> >>',
    );

    final pageId = builder.addObject(
      '<< /Type /Page /Parent 0 0 R /MediaBox [0 0 595 842] '
      '/Resources $resourcesId 0 R /Contents $contentId 0 R >>',
    );

    final pagesId = builder.addObject(
      '<< /Type /Pages /Kids [$pageId 0 R] /Count 1 >>',
    );
    builder.replaceInObject(pageId, '/Parent 0 0 R', '/Parent $pagesId 0 R');

    final xmpString = buildAeatXmp(
      title: content.title,
      author: ComplianceConstants.softwareName,
      docId: docId,
      homologationRef: ComplianceConstants.homologationReference,
      timestamp: timestamp,
      softwareName: ComplianceConstants.softwareName,
      softwareVersion: ComplianceConstants.softwareVersion,
    );
    final xmpBytes = utf8.encode(xmpString);
    final metadataId = builder.addStream(
      '<< /Type /Metadata /Subtype /XML /Length ${xmpBytes.length} >>',
      xmpBytes,
    );

    final catalogId = builder.addObject(
      '<< /Type /Catalog /Pages $pagesId 0 R /Metadata $metadataId 0 R /Lang (es-ES) >>',
    );

    final fileIdHex = _buildFileIdHex(docId);
    return builder.build(
      rootId: catalogId,
      infoId: infoId,
      fileIdHex: fileIdHex,
    );
  }
}

_InvoicePageLayout _buildLayout(InvoicePdfContent content) {
  const pageWidth = 595.0;
  const pageHeight = 842.0;
  const cardWidth = 360.0;
  const cardTopMargin = 72.0;
  const paddingTop = 36.0;
  const paddingBottom = 40.0;
  const paddingHorizontal = 30.0;

  final cardLeft = (pageWidth - cardWidth) / 2;
  final cardTop = pageHeight - cardTopMargin;

  final builder = _InvoiceLayoutBuilder(
    cardLeft: cardLeft,
    cardTop: cardTop,
    cardWidth: cardWidth,
    paddingTop: paddingTop,
    paddingBottom: paddingBottom,
    paddingHorizontal: paddingHorizontal,
  );

  builder.addTitle('FACTURA');
  builder.addLabelValue('NUMERO', content.invoiceNumber ?? 'NO DISPONIBLE');
  builder.addLabelValue('FECHA', _formatDate(content.issueDate));
  builder.addStatusChip(content.status.labelEs);

  builder.addSeparator();

  final issuerLines = _partyDetails(
    content.issuerName,
    content.issuerTaxId,
    content.issuerAddress,
    builder.cardContentWidth,
  );
  if (issuerLines.isNotEmpty) {
    builder.addSectionTitle('EMISOR');
    builder.addBodyLines(issuerLines);
    builder.addSeparator();
  }

  final receiverLines = _partyDetails(
    content.receiverName,
    content.receiverTaxId,
    content.receiverAddress,
    builder.cardContentWidth,
  );
  if (receiverLines.isNotEmpty) {
    builder.addSectionTitle('RECEPTOR');
    builder.addBodyLines(receiverLines);
    builder.addSeparator();
  }

  final paragraphWidth = builder.cardContentWidth - 24.0;
  final conceptLines = _wrapParagraph(content.concept, paragraphWidth);
  if (conceptLines.isNotEmpty) {
    final isPedido = _isPedido(content.concept);
    builder.addSectionTitle(isPedido ? 'PEDIDO' : 'CONCEPTO');
    builder.addParagraphBox(conceptLines);
    builder.addSeparator();
  }

  builder.addSectionTitle('RESUMEN IMPORTE');
  builder.addAmountTable(
    rows: [
      _AmountRow(
        'BASE IMPONIBLE',
        _formatMoney(content.netAmount, content.currency),
      ),
      _AmountRow(
        _formatVatLabel(content.vatRate),
        _formatMoney(content.ivaAmount, content.currency),
      ),
    ],
    total: _AmountRow('TOTAL', _formatMoney(content.total, content.currency)),
  );

  if (content.attachmentImageBytes != null) {
    builder.addSeparator();
    builder.addSectionTitle('ADJUNTOS');
    builder.addParagraphBox(
      _wrapParagraph('Imagen disponible en la aplicacion', paragraphWidth),
    );
  }

  builder.addSeparator();
  builder.addFooter('GENERADO POR GESTR APP');

  final layout = builder.build();
  layout.rects.insert(
    0,
    const _DrawRect(
      left: 0,
      bottom: 0,
      width: pageWidth,
      height: pageHeight,
      color: _PdfColor(0.93, 0.98, 0.99),
    ),
  );
  layout.rects.insert(
    1,
    _DrawRect(
      left: cardLeft + 6,
      bottom: layout.cardBottom - 6,
      width: cardWidth,
      height: layout.cardTop - layout.cardBottom,
      color: const _PdfColor(0.86, 0.95, 0.96),
    ),
  );
  layout.rects.insert(
    2,
    _DrawRect(
      left: cardLeft,
      bottom: layout.cardBottom,
      width: cardWidth,
      height: layout.cardTop - layout.cardBottom,
      color: const _PdfColor(1, 1, 1),
    ),
  );

  return layout;
}

bool _isPedido(String? concept) {
  if (concept == null) return false;
  if (concept.contains('\n')) return true;
  final lower = concept.toLowerCase();
  return lower.contains(' x ') && lower.contains('@');
}

String _buildContentStream(_InvoicePageLayout layout) {
  final buffer =
      StringBuffer()
        ..writeln('q')
        ..writeln('/CS0 cs');

  for (final rect in layout.rects) {
    buffer
      ..writeln(
        '${_formatNumber(rect.color.r)} ${_formatNumber(rect.color.g)} ${_formatNumber(rect.color.b)} sc',
      )
      ..writeln(
        '${_formatNumber(rect.left)} ${_formatNumber(rect.bottom)} ${_formatNumber(rect.width)} ${_formatNumber(rect.height)} re',
      )
      ..writeln('f');
  }

  for (final text in layout.texts) {
    final glyphs = PixelFont.buildLineRects(
      text.text,
      left: text.left,
      topY: text.top,
      fontSize: text.fontSize,
    );

    var hasGlyph = false;
    buffer.writeln(
      '${_formatNumber(text.color.r)} ${_formatNumber(text.color.g)} ${_formatNumber(text.color.b)} sc',
    );
    for (final rect in glyphs) {
      buffer.writeln(
        '${_formatNumber(rect.x)} ${_formatNumber(rect.y)} ${_formatNumber(rect.width)} ${_formatNumber(rect.height)} re',
      );
      hasGlyph = true;
    }
    if (hasGlyph) {
      buffer.writeln('f');
    }
  }

  buffer.writeln('Q');
  return buffer.toString();
}

class _InvoiceLayoutBuilder {
  _InvoiceLayoutBuilder({
    required this.cardLeft,
    required this.cardTop,
    required this.cardWidth,
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingHorizontal,
  }) : cursor = cardTop - paddingTop,
       cardContentLeft = cardLeft + paddingHorizontal,
       cardContentWidth = cardWidth - paddingHorizontal * 2;

  final double cardLeft;
  final double cardTop;
  final double cardWidth;
  final double paddingTop;
  final double paddingBottom;
  final double paddingHorizontal;

  final double cardContentLeft;
  final double cardContentWidth;

  double cursor;
  double minY = double.infinity;

  final List<_DrawRect> _rects = [];
  final List<_DrawText> _texts = [];
  final List<String> _coverageStrings = [];

  static const _PdfColor _primaryText = _PdfColor(0.09, 0.11, 0.13);
  static const _PdfColor _mutedText = _PdfColor(0.41, 0.44, 0.48);
  static const _PdfColor _chipBackground = _PdfColor(0.64, 0.91, 0.81);
  static const _PdfColor _chipText = _PdfColor(0.06, 0.3, 0.23);
  static const _PdfColor _separatorColor = _PdfColor(0.87, 0.89, 0.92);
  static const _PdfColor _boxBackground = _PdfColor(0.9, 0.91, 0.94);
  static const _PdfColor _tableBackground = _PdfColor(0.95, 0.97, 0.99);
  static const _PdfColor _totalBackground = _PdfColor(0.12, 0.39, 0.23);
  static const _PdfColor _totalText = _PdfColor(1, 1, 1);

  static const double _titleFontSize = 20.0;
  static const double _valueFontSize = 13.0;
  static const double _labelFontSize = 9.5;
  static const double _sectionFontSize = 12.0;
  static const double _bodyFontSize = 11.0;
  static const double _totalFontSize = 14.0;

  List<String> get coverageStrings => _coverageStrings;
  double get cardBottom =>
      minY.isFinite
          ? minY - paddingBottom
          : cardTop - paddingTop - paddingBottom;

  void addTitle(String text) {
    _addLine(
      PixelFont.sanitize(text),
      fontSize: _titleFontSize,
      color: _primaryText,
      gapAfter: 18,
    );
  }

  void addLabelValue(String label, String value) {
    final sanitizedLabel = PixelFont.sanitize(label);
    if (sanitizedLabel.isNotEmpty) {
      _addLine(
        sanitizedLabel,
        fontSize: _labelFontSize,
        color: _mutedText,
        gapAfter: 2,
      );
    }

    final sanitizedValue = PixelFont.sanitize(value);
    if (sanitizedValue.isNotEmpty) {
      _addLine(
        sanitizedValue,
        fontSize: _valueFontSize,
        color: _primaryText,
        gapAfter: 12,
      );
    }
  }

  void addStatusChip(String status) {
    final sanitized = PixelFont.sanitize(status);
    if (sanitized.isEmpty) {
      return;
    }

    const chipFont = 11.0;
    const horizontalPadding = 10.0;
    const verticalPadding = 6.0;

    final textWidth = PixelFont.measureWidth(sanitized, chipFont);
    final lineHeight = PixelFont.lineHeight(chipFont);

    final availableWidth = cardContentWidth;
    final rectWidth = min(textWidth + horizontalPadding * 2, availableWidth);
    final rectHeight = lineHeight + verticalPadding * 2;
    final rectBottom = cursor - rectHeight;

    _rects.add(
      _DrawRect(
        left: cardContentLeft,
        bottom: rectBottom,
        width: rectWidth,
        height: rectHeight,
        color: _chipBackground,
      ),
    );

    final textLeft =
        cardContentLeft + min(horizontalPadding, (rectWidth - textWidth) / 2);
    _addText(
      sanitized,
      top: rectBottom + rectHeight - verticalPadding,
      fontSize: chipFont,
      color: _chipText,
      gapAfter: 14,
      leftOffset: textLeft - cardContentLeft,
    );
  }

  void addSeparator() {
    const thickness = 1.0;
    const gapBefore = 10.0;
    const gapAfter = 16.0;

    cursor -= gapBefore;
    final bottom = cursor - thickness;

    _rects.add(
      _DrawRect(
        left: cardContentLeft,
        bottom: bottom,
        width: cardContentWidth,
        height: thickness,
        color: _separatorColor,
      ),
    );

    cursor = bottom - gapAfter;
    minY = min(minY, bottom);
  }

  void addSectionTitle(String text) {
    _addLine(
      PixelFont.sanitize(text),
      fontSize: _sectionFontSize,
      color: _primaryText,
      gapAfter: 10,
    );
  }

  void addBodyLines(List<String> lines) {
    for (final line in lines) {
      _addLine(line, fontSize: _bodyFontSize, color: _primaryText, gapAfter: 6);
    }
  }

  void addParagraphBox(List<String> lines) {
    if (lines.isEmpty) {
      return;
    }

    const horizontalPadding = 12.0;
    const verticalPadding = 10.0;
    const lineGap = 4.0;

    final lineHeight = PixelFont.lineHeight(_bodyFontSize);
    final contentHeight =
        lines.length * lineHeight + max(0, lines.length - 1) * lineGap;
    final boxHeight = contentHeight + 2 * verticalPadding;
    final boxWidth = cardContentWidth;
    final bottom = cursor - boxHeight;

    _rects.add(
      _DrawRect(
        left: cardContentLeft,
        bottom: bottom,
        width: boxWidth,
        height: boxHeight,
        color: _boxBackground,
      ),
    );

    var lineTop = cursor - verticalPadding;
    for (final line in lines) {
      _addText(
        line,
        top: lineTop,
        fontSize: _bodyFontSize,
        color: _primaryText,
        gapAfter: lineGap,
        leftOffset: horizontalPadding,
      );
      lineTop -= lineHeight + lineGap;
    }

    cursor = bottom - 14;
    minY = min(minY, bottom);
  }

  void addAmountTable({
    required List<_AmountRow> rows,
    required _AmountRow total,
  }) {
    if (rows.isEmpty) {
      return;
    }

    const paddingY = 12.0;
    const paddingX = 12.0;
    const rowGap = 6.0;

    final lineHeight = PixelFont.lineHeight(_bodyFontSize);
    final contentHeight =
        rows.length * lineHeight + max(0, rows.length - 1) * rowGap;
    final boxHeight = contentHeight + 2 * paddingY;
    final boxBottom = cursor - boxHeight;

    _rects.add(
      _DrawRect(
        left: cardContentLeft,
        bottom: boxBottom,
        width: cardContentWidth,
        height: boxHeight,
        color: _tableBackground,
      ),
    );

    var rowTop = cursor - paddingY;
    for (final row in rows) {
      final label = PixelFont.sanitize(row.label);
      final value = PixelFont.sanitize(row.value);

      _addText(
        label,
        top: rowTop,
        fontSize: _bodyFontSize,
        color: _mutedText,
        gapAfter: 0,
        leftOffset: paddingX,
      );

      final valueWidth = PixelFont.measureWidth(value, _bodyFontSize);
      final valueLeft = cardContentWidth - paddingX - valueWidth;
      _addText(
        value,
        top: rowTop,
        fontSize: _bodyFontSize,
        color: _primaryText,
        gapAfter: 0,
        leftOffset: max(paddingX, valueLeft),
      );

      final bottom = rowTop - lineHeight;
      rowTop = bottom - rowGap;
      minY = min(minY, bottom);
    }

    cursor = boxBottom - 18;
    minY = min(minY, boxBottom);

    final totalLabel = PixelFont.sanitize(total.label);
    final totalValue = PixelFont.sanitize(total.value);

    const totalPaddingY = 9.0;
    const totalPaddingX = 14.0;
    final totalLineHeight = PixelFont.lineHeight(_totalFontSize);
    final totalHeight = totalLineHeight + totalPaddingY * 2;
    final totalBottom = cursor - totalHeight;

    _rects.add(
      _DrawRect(
        left: cardContentLeft,
        bottom: totalBottom,
        width: cardContentWidth,
        height: totalHeight,
        color: _totalBackground,
      ),
    );

    _addText(
      totalLabel,
      top: totalBottom + totalHeight - totalPaddingY,
      fontSize: _totalFontSize,
      color: _totalText,
      gapAfter: 0,
      leftOffset: totalPaddingX,
    );

    final totalWidth = PixelFont.measureWidth(totalValue, _totalFontSize);
    final totalLeft = cardContentWidth - totalPaddingX - totalWidth;
    _addText(
      totalValue,
      top: totalBottom + totalHeight - totalPaddingY,
      fontSize: _totalFontSize,
      color: _totalText,
      gapAfter: 0,
      leftOffset: max(totalPaddingX, totalLeft),
    );

    cursor = totalBottom - 20;
    minY = min(minY, totalBottom);
  }

  void addFooter(String text) {
    _addLine(
      PixelFont.sanitize(text),
      fontSize: _labelFontSize,
      color: _mutedText,
      gapAfter: 0,
    );
  }

  _InvoicePageLayout build() {
    final contentBottom = minY.isFinite ? minY : cursor;
    final resolvedCardBottom = contentBottom - paddingBottom;

    return _InvoicePageLayout(
      rects: _rects,
      texts: _texts,
      coverageStrings: _coverageStrings,
      cardBottom: resolvedCardBottom,
      cardTop: cardTop,
    );
  }

  void _addLine(
    String text, {
    required double fontSize,
    required _PdfColor color,
    required double gapAfter,
  }) {
    if (text.isEmpty) {
      cursor -= gapAfter;
      return;
    }

    _addText(
      text,
      top: cursor,
      fontSize: fontSize,
      color: color,
      gapAfter: gapAfter,
    );
  }

  void _addText(
    String text, {
    required double top,
    required double fontSize,
    required _PdfColor color,
    required double gapAfter,
    double leftOffset = 0,
  }) {
    if (text.isEmpty) {
      cursor = top - gapAfter;
      return;
    }

    final lineHeight = PixelFont.lineHeight(fontSize);
    final left = cardContentLeft + leftOffset;

    _texts.add(
      _DrawText(
        text: text,
        left: left,
        top: top,
        fontSize: fontSize,
        color: color,
      ),
    );
    _coverageStrings.add(text);

    final bottom = top - lineHeight;
    cursor = bottom - gapAfter;
    minY = min(minY, bottom);
  }
}

class _InvoicePageLayout {
  _InvoicePageLayout({
    required this.rects,
    required this.texts,
    required this.coverageStrings,
    required this.cardBottom,
    required this.cardTop,
  });

  final List<_DrawRect> rects;
  final List<_DrawText> texts;
  final List<String> coverageStrings;
  final double cardBottom;
  final double cardTop;
}

class _DrawRect {
  const _DrawRect({
    required this.left,
    required this.bottom,
    required this.width,
    required this.height,
    required this.color,
  });

  final double left;
  final double bottom;
  final double width;
  final double height;
  final _PdfColor color;
}

class _DrawText {
  const _DrawText({
    required this.text,
    required this.left,
    required this.top,
    required this.fontSize,
    required this.color,
  });

  final String text;
  final double left;
  final double top;
  final double fontSize;
  final _PdfColor color;
}

class _PdfColor {
  const _PdfColor(this.r, this.g, this.b);

  final double r;
  final double g;
  final double b;
}

class _AmountRow {
  const _AmountRow(this.label, this.value);

  final String label;
  final String value;
}

String _formatVatLabel(double? vatRate) {
  if (vatRate == null) {
    return 'IVA';
  }
  final rate = vatRate.abs();
  var text = rate.toStringAsFixed(2);
  while (text.contains('.') && (text.endsWith('0') || text.endsWith('.'))) {
    text = text.substring(0, text.length - 1);
  }
  return 'IVA ($text%)';
}

String _composeKeyValue(String key, String value) {
  final sanitizedKey = PixelFont.sanitize(key);
  final sanitizedValue = PixelFont.sanitize(value);
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
  final sanitizedCurrency = PixelFont.sanitize(currency);
  final amount = value.toStringAsFixed(2);
  return sanitizedCurrency.isEmpty ? amount : '$amount $sanitizedCurrency';
}

List<String> _wrapParagraph(String? text, double maxWidth) {
  if (text == null || text.trim().isEmpty) {
    return <String>[];
  }
  return PixelFont.wrap(text, fontSize: 11.0, maxWidth: maxWidth);
}

List<String> _partyDetails(
  String? name,
  String? taxId,
  String? address,
  double maxWidth,
) {
  final buffer = <String>[];
  if (name != null && name.trim().isNotEmpty) {
    buffer.addAll(PixelFont.wrap(name, fontSize: 11.0, maxWidth: maxWidth));
  }
  if (taxId != null && taxId.trim().isNotEmpty) {
    buffer.add(_composeKeyValue('NIF', taxId));
  }
  if (address != null && address.trim().isNotEmpty) {
    buffer.addAll(PixelFont.wrap(address, fontSize: 11.0, maxWidth: maxWidth));
  }
  return buffer;
}

String _escapeLiteral(String text) {
  return text
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
}

String _buildFileIdHex(String seed) {
  final source = seed.isEmpty ? 'gestr-doc-id' : seed;
  final bytes = List<int>.generate(16, (index) {
    final char = source.codeUnitAt(index % source.length);
    return (char + index) & 0xff;
  });

  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

String _formatNumber(double value) {
  const epsilon = 1e-6;
  if ((value - value.roundToDouble()).abs() < epsilon) {
    return value.round().toString();
  }
  var text = value.toStringAsFixed(3);
  while (text.contains('.') && (text.endsWith('0') || text.endsWith('.'))) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}
