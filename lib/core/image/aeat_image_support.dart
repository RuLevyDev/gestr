import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

/// Utilities to generate the AEAT-required image formats from a single source
/// file. The AEAT admits PNG, JPEG 2000, TIFF 6.0 and PDF 1.4+ with lossless
/// compression for digital invoices and receipts. This helper produces local
/// conversions for PNG, TIFF and PDF while delegating JPEG 2000 to an optional
/// backend (exposed via the `AEAT_JPEG2000_URL` environment variable).
class AeatImageSupport {
  const AeatImageSupport._();

  /// Converts [file] into the AEAT accepted formats. The optional [baseName]
  /// parameter lets callers customise the output filenames. When omitted the
  /// original file name (without extension) is used.
  static Future<List<AeatImageAttachment>> generateAttachments(
    File file, {
    String? baseName,
  }) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('No se pudo decodificar la imagen en ${file.path}');
    }

    final sanitizedName = _sanitizeBaseName(
      baseName ?? _deriveBaseName(file.path),
    );
    final attachments = <AeatImageAttachment>[];

    final pngBytes = Uint8List.fromList(img.encodePng(decoded));
    attachments.add(
      AeatImageAttachment(
        filename: '$sanitizedName.png',
        mimeType: 'image/png',
        bytes: pngBytes,
      ),
    );

    final tiffBytes = Uint8List.fromList(img.encodeTiff(decoded));
    attachments.add(
      AeatImageAttachment(
        filename: '$sanitizedName.tiff',
        mimeType: 'image/tiff',
        bytes: tiffBytes,
      ),
    );

    final pdfBytes = await _encodeLosslessPdf(decoded);
    attachments.add(
      AeatImageAttachment(
        filename: '${sanitizedName}_lossless.pdf',
        mimeType: 'application/pdf',
        bytes: pdfBytes,
      ),
    );

    final jpeg2000 = await _encodeJpeg2000(decoded);
    if (jpeg2000 != null && jpeg2000.isNotEmpty) {
      attachments.add(
        AeatImageAttachment(
          filename: '$sanitizedName.jp2',
          mimeType: 'image/jp2',
          bytes: jpeg2000,
        ),
      );
    }

    return attachments;
  }

  /// Sanitises a free-form label and converts it into a slug that is safe to
  /// use in filenames. Public so UI layers can reuse the logic when building
  /// share texts or storage keys.
  static String sanitizeLabel(String label) => _sanitizeBaseName(label);

  static Future<Uint8List> _encodeLosslessPdf(img.Image image) async {
    final document = pw.Document(
      version: pdf.PdfVersion.pdf_1_4,
      compress: true,
    );
    final pngBytes = Uint8List.fromList(img.encodePng(image));
    final memory = pw.MemoryImage(pngBytes);

    document.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build:
            (_) => pw.Center(child: pw.Image(memory, fit: pw.BoxFit.contain)),
      ),
    );

    final saved = await document.save();
    return Uint8List.fromList(saved);
  }

  static Future<Uint8List?> _encodeJpeg2000(img.Image image) async {
    final endpoint = _resolveJpeg2000Endpoint();
    if (endpoint.isEmpty) {
      return null;
    }

    final pngBytes = Uint8List.fromList(img.encodePng(image));
    try {
      final uri = Uri.parse(endpoint);
      final payload = jsonEncode(<String, dynamic>{
        'image': base64Encode(pngBytes),
        'format': 'png',
      });

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'image/jp2',
        },
        body: payload,
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return Uint8List.fromList(response.bodyBytes);
      }
    } catch (_) {
      // Si falla, simplemente no se adjunta la variante JPEG 2000.
    }

    return null;
  }

  static String _resolveJpeg2000Endpoint() {
    const compiled = String.fromEnvironment('AEAT_JPEG2000_URL');
    if (compiled.isNotEmpty) {
      return compiled;
    }
    return Platform.environment['AEAT_JPEG2000_URL'] ?? '';
  }

  static String _deriveBaseName(String path) {
    final normalised = path.replaceAll('\\', '/');
    final segments = normalised.split('/');
    final lastSegment = segments.isNotEmpty ? segments.last : path;
    if (lastSegment.isEmpty) {
      return 'documento';
    }
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex > 0) {
      return lastSegment.substring(0, dotIndex);
    }
    return lastSegment;
  }

  static String _sanitizeBaseName(String raw) {
    final trimmed = raw.trim();
    final base = trimmed.isEmpty ? 'documento' : trimmed.toLowerCase();
    final replaced = base
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_'), '')
        .replaceAll(RegExp(r'_$'), '');
    if (replaced.isEmpty) {
      return 'documento';
    }
    return replaced.length > 48 ? replaced.substring(0, 48) : replaced;
  }
}

class AeatImageAttachment {
  const AeatImageAttachment({
    required this.filename,
    required this.mimeType,
    required this.bytes,
  });

  final String filename;
  final String mimeType;
  final Uint8List bytes;
}
