import 'dart:convert';
import 'dart:typed_data';

import 'package:gestr/core/config/compliance_constants.dart';
import 'package:gestr/core/pdf/aeat_xmp.dart';
import 'package:gestr/core/pdf/pdfa_document_builder.dart';
import 'package:gestr/core/pdf/pixel_font.dart';

/// Utility to build minimalist PDF/A-1b compliant sample documents.
///
/// The implementation mirrors the manual generator used by
/// `tool/generate_sample_pdfs.dart` so the same PDF structure is available in
/// the Flutter application. Only a limited character set is supported; use
/// [sanitizeLine] to normalize arbitrary user input into a compatible form.
class PdfaGenerator {
  const PdfaGenerator._();

  /// Generates a PDF document using the provided [lines].
  static Uint8List generate({
    required String title,
    required String author,
    required String docId,
    required List<String> lines,
    String? homologationRef,
    DateTime? timestamp,
    String? softwareName,
    String? softwareVersion,
  }) {
    final sanitizedLines =
        lines.map(PixelFont.sanitize).where((line) => line.isNotEmpty).toList();
    PixelFont.ensureCoverage(sanitizedLines);

    final builder = PdfaDocumentBuilder();

    final resolvedTimestamp = (timestamp ?? DateTime.now()).toUtc();
    final resolvedSoftwareName = _resolveSoftwareName(softwareName);
    final resolvedSoftwareVersion = _resolveSoftwareVersion(softwareVersion);

    final literalTitle = _escapeLiteral(title);
    final literalAuthor = _escapeLiteral(author);
    final literalProducer = _escapeLiteral(resolvedSoftwareName);
    final pdfDate = _formatPdfDate(resolvedTimestamp);
    final infoId = builder.addObject(
      '<< /Title ($literalTitle) /Author ($literalAuthor) '
      '/Producer ($literalProducer) '
      '/CreationDate ($pdfDate) /ModDate ($pdfDate) >>',
    );

    final contentString = _buildContentStream(sanitizedLines);
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
      title: title,
      author: author,
      docId: docId,
      homologationRef: homologationRef,
      timestamp: resolvedTimestamp,
      softwareName: resolvedSoftwareName,
      softwareVersion: resolvedSoftwareVersion,
    );
    final xmpBytes = utf8.encode(xmpString);
    final metadataId = builder.addStream(
      '<< /Type /Metadata /Subtype /XML /Length ${xmpBytes.length} >>',
      xmpBytes,
    );

    final catalogId = builder.addObject(
      '<< /Type /Catalog /Pages $pagesId 0 R /Metadata $metadataId 0 R /Lang (en-US) >>',
    );

    final fileIdHex = _buildFileIdHex(docId);
    return builder.build(
      rootId: catalogId,
      infoId: infoId,
      fileIdHex: fileIdHex,
    );
  }

  /// Normalizes an arbitrary [text] so it only includes characters supported by
  /// the sample glyph set.
  static String sanitizeLine(String text) => PixelFont.sanitize(text);

  /// Generates a safe identifier for the PDF metadata.
  static String generateDocId(String seed) {
    final sanitized = sanitizeLine(seed).replaceAll(' ', '-');
    final fallback = sanitized.isEmpty ? 'GESTR-DOC' : sanitized;
    return fallback.length > 32 ? fallback.substring(0, 32) : fallback;
  }
}

String _formatPdfDate(DateTime timestamp) {
  final utc = timestamp.toUtc();
  final year = utc.year.toString().padLeft(4, '0');
  final month = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  final hour = utc.hour.toString().padLeft(2, '0');
  final minute = utc.minute.toString().padLeft(2, '0');
  final second = utc.second.toString().padLeft(2, '0');
  return 'D:$year$month$day$hour$minute${second}Z';
}

String _buildContentStream(List<String> lines) {
  const startX = 72.0;
  const startY = 720.0;
  const fontSize = 12.0;
  const leading = 18.0;

  final buffer =
      StringBuffer()
        ..writeln('q')
        ..writeln('/CS0 cs')
        ..writeln('0 0 0 sc');

  final rectangles = <String>[];

  for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    final line = lines[lineIndex];
    final topY = startY - lineIndex * leading;
    for (final rect in PixelFont.buildLineRects(
      line,
      left: startX,
      topY: topY,
      fontSize: fontSize,
    )) {
      rectangles.add(
        '${_formatNumber(rect.x)} ${_formatNumber(rect.y)} ${_formatNumber(rect.width)} ${_formatNumber(rect.height)} re',
      );
    }
  }

  if (rectangles.isNotEmpty) {
    buffer.writeln(rectangles.join('\n'));
    buffer.writeln('f');
  }

  buffer.writeln('Q');
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

String _resolveSoftwareName(String? value) {
  if (value != null && value.trim().isNotEmpty) {
    return value.trim();
  }
  return ComplianceConstants.softwareName;
}

String _resolveSoftwareVersion(String? value) {
  if (value != null && value.trim().isNotEmpty) {
    return value.trim();
  }
  return ComplianceConstants.softwareVersion;
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

String _escapeText(String text) {
  return text
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
}

String _escapeLiteral(String text) => _escapeText(text);
