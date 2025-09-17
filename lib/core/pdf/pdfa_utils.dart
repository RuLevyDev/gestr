import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;

/// Minimal helpers to get closer to PDF/A requirements in client-side PDFs.
/// - Uses PDF 1.4 (required by PDF/A-1)

/// - Provides a Helvetica-based fallback theme that works in pure Dart
///   environments while allowing callers to inject custom embedded fonts.
/// Note: Full PDF/A conformance (XMP metadata, OutputIntent/ICC profile, etc.)
/// is typically done server-side or with specialized tooling.
class PdfaBackendRequest {
  const PdfaBackendRequest({
    this.enabled = true,
    this.requestXmp = false,
    this.requestOutputIntent = false,
    this.metadata = const <String, String>{},
    this.profile = 'PDF/A-1b',
  });

  const PdfaBackendRequest.strict({
    Map<String, String> metadata = const <String, String>{},
    String profile = 'PDF/A-1b',
  }) : this(
         enabled: true,
         requestXmp: true,
         requestOutputIntent: true,
         metadata: metadata,
         profile: profile,
       );

  const PdfaBackendRequest.disabled() : this(enabled: false);

  final bool enabled;
  final bool requestXmp;
  final bool requestOutputIntent;
  final Map<String, String> metadata;
  final String profile;

  bool get hasMetadata => metadata.isNotEmpty;
}

class PdfAUtils {
  /// Create a document targeting PDF 1.4 with compression enabled.
  static pw.Document createDocument() {
    return pw.Document(version: pdf.PdfVersion.pdf_1_4, compress: true);
  }

  /// Provides a [pw.PageTheme] using either the supplied [theme] or the
  /// lazily-initialised Helvetica fallback that is compatible with pure Dart
  /// environments.
  static Future<pw.PageTheme> pageTheme({pw.ThemeData? theme}) async {
    return pw.PageTheme(theme: theme ?? defaultTheme());
  }

  static pw.ThemeData? _cachedDefaultTheme;

  /// Returns the default theme used when no custom fonts are injected.
  static pw.ThemeData defaultTheme() {
    return _cachedDefaultTheme ??= pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
    );
  }

  /// Flattens transparency against white and encodes as baseline JPEG so the
  /// embedded image never carries an alpha channel (which PDF/A-1 forbids).
  /// If decoding fails, returns the original bytes.
  static Future<Uint8List> prepareImageBytesForPdfA(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    // Create white background and composite decoded image over it to guarantee
    // there is no residual transparency before encoding as JPEG.
    final whiteBg = img.Image(width: decoded.width, height: decoded.height);
    img.fill(whiteBg, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(whiteBg, decoded);

    final jpgBytes = img.encodeJpg(whiteBg, quality: 92);
    return Uint8List.fromList(jpgBytes);
  }

  /// Optionally send the generated PDF to a backend that normalizes to strict PDF/A-1b.
  /// If the env `PDFA_NORMALIZE_URL` is not set or the call fails, returns the original bytes.
  static Future<Uint8List> maybeNormalizeOnBackend(
    Uint8List pdfBytes, {
    PdfaBackendRequest request = const PdfaBackendRequest.strict(),
  }) async {
    if (!request.enabled) return pdfBytes;

    final endpoint = _resolveNormalizationEndpoint();
    if (endpoint.isEmpty) return pdfBytes;
    try {
      final uri = Uri.parse(endpoint);
      final headers = <String, String>{
        'Accept': 'application/pdf',
        'X-Pdfa-Profile': request.profile,
      };

      if (request.requestXmp) {
        headers['X-Pdfa-Request-Xmp'] = '1';
      }
      if (request.requestOutputIntent) {
        headers['X-Pdfa-Request-OutputIntent'] = '1';
      }

      http.Response res;
      if (request.hasMetadata) {
        headers['Content-Type'] = 'application/json';
        final payload = jsonEncode({
          'pdf': base64Encode(pdfBytes),
          'metadata': request.metadata,
          'profile': request.profile,
          'requestXmp': request.requestXmp,
          'requestOutputIntent': request.requestOutputIntent,
        });
        res = await http.post(uri, headers: headers, body: payload);
      } else {
        headers['Content-Type'] = 'application/pdf';
        res = await http.post(uri, headers: headers, body: pdfBytes);
      }
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return Uint8List.fromList(res.bodyBytes);
      }
    } catch (_) {
      // Swallow and fallback to original bytes
    }
    return pdfBytes;
  }

  static String _resolveNormalizationEndpoint() {
    const compiled = String.fromEnvironment('PDFA_NORMALIZE_URL');
    if (compiled.isNotEmpty) {
      return compiled;
    }
    return Platform.environment['PDFA_NORMALIZE_URL'] ?? '';
  }
}
