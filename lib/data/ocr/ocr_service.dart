import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Servicio encargado de procesar imágenes usando Google ML Kit
/// y devolver el texto reconocido.
class OcrService {
  // Be explicit about the script; invoices are Latin by default (es/en)
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Procesa la [image] recibida y retorna el texto completo detectado.
  Future<String> processImage(File image) async {
    // Debug: log image path and size
    try {
      final size = await image.length();
      // ignore: avoid_print
      print('[OCR] Processing image: ${image.path} ($size bytes)');
    } catch (_) {}

    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognised = await _textRecognizer.processImage(
      inputImage,
    );
    // Debug: log recognised text length and preview
    final text = recognised.text;
    // ignore: avoid_print
    print('[OCR] Recognized length: ${text.length}');
    if (text.isNotEmpty) {
      final preview = text.split('\n').take(10).join(' | ');
      // ignore: avoid_print
      print('[OCR] Preview: $preview');
    }
    return text;
  }

  /// Libera los recursos del reconocedor de texto.
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
