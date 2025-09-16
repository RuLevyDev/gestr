import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

/// Minimal helpers to get closer to PDF/A requirements in client-side PDFs.
/// - Uses PDF 1.4 (required by PDF/A-1)
/// - Embeds fonts via Google Fonts helpers (fonts are embedded in the file)
/// Note: Full PDF/A conformance (XMP metadata, OutputIntent/ICC profile, etc.)
/// is typically done server-side or with specialized tooling.
class PdfAUtils {
  /// Create a document targeting PDF 1.4 with compression enabled.
  static pw.Document createDocument() {
    return pw.Document(version: pdf.PdfVersion.pdf_1_4, compress: true);
  }

  /// Provides a PageTheme with fonts. Uses built-in Helvetica for now.
  static Future<pw.PageTheme> pageTheme() async {
    return pw.PageTheme(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );
  }

  /// Flattens transparency and encodes as PNG (lossless) to reduce PDF/A-1 issues.
  /// If decoding fails, returns the original bytes.
  static Future<Uint8List> prepareImageBytesForPdfA(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    // Create white background and composite decoded image over it.
    final whiteBg = img.Image(width: decoded.width, height: decoded.height);
    img.fill(whiteBg, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(whiteBg, decoded);

    final pngBytes = img.encodePng(whiteBg, level: 6);
    return Uint8List.fromList(pngBytes);
  }

  /// Optionally send the generated PDF to a backend that normalizes to strict PDF/A-1b.
  /// If the env `PDFA_NORMALIZE_URL` is not set or the call fails, returns the original bytes.
  static Future<Uint8List> maybeNormalizeOnBackend(Uint8List pdfBytes) async {
    const endpoint = String.fromEnvironment('PDFA_NORMALIZE_URL');
    if (endpoint.isEmpty) return pdfBytes;
    try {
      final uri = Uri.parse(endpoint);
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/pdf',
          'Accept': 'application/pdf',
        },
        body: pdfBytes,
      );
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return Uint8List.fromList(res.bodyBytes);
      }
    } catch (_) {
      // Swallow and fallback to original bytes
    }
    return pdfBytes;
  }
}
