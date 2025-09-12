import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Servicio encargado de procesar imágenes usando Google ML Kit
/// y devolver el texto reconocido.
class OcrService {
  // Be explicit about the script; invoices are Latin by default (es/en)
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Procesa la [image] recibida y retorna el texto completo detectado.
  Future<String> processImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognised = await _textRecognizer.processImage(
      inputImage,
    );
    return recognised.text;
  }

  /// Libera los recursos del reconocedor de texto.
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
