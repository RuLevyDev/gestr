import 'dart:io';
import 'package:gestr/data/ocr/ocr_service.dart';
import 'package:gestr/domain/entities/ocr_invoice_data.dart';
import 'package:gestr/domain/repositories/ocr/ocr_repository.dart';
import 'package:intl/intl.dart';

/// Implementación del [OcrRepository] que utiliza [OcrService]
/// para extraer y normalizar la información de una imagen.
class OcrRepositoryImpl implements OcrRepository {
  final OcrService _service;

  OcrRepositoryImpl(this._service);

  @override
  Future<OcrInvoiceData> extractData(File image) async {
    final rawText = await _service.processImage(image);

    // Título: primera línea del texto detectado
    final lines = rawText.split('\n');
    final String? title = lines.isNotEmpty ? lines.first : null;

    // Búsqueda de un importe con dos decimales (validación de formato)
    final amountMatch = RegExp(r'([0-9]+[.,][0-9]{2})').firstMatch(rawText);
    final double? amount =
        amountMatch != null
            ? double.tryParse(amountMatch.group(1)!.replaceAll(',', '.'))
            : null;

    // Búsqueda de fecha en formato ISO y validación estricta
    DateTime? date;
    final dateMatch = RegExp(
      r'([0-9]{4}-[0-9]{2}-[0-9]{2})',
    ).firstMatch(rawText);
    if (dateMatch != null) {
      try {
        date = DateFormat('yyyy-MM-dd').parseStrict(dateMatch.group(1)!);
      } catch (_) {
        date = null;
      }
    }
    // Extracción de campos adicionales
    final issuer = _extractField(rawText, ['Emisor', 'Issuer']);
    final receiver = _extractField(rawText, ['Receptor', 'Receiver']);
    final concept = _extractField(rawText, ['Concepto', 'Concept']);

    return OcrInvoiceData(
      title: title,
      amount: amount,
      date: date,
      issuer: issuer,
      receiver: receiver,
      concept: concept,
    );
  }

  String? _extractField(String text, List<String> labels) {
    // Split by real newlines; previous split('\\n') was incorrect
    final lines = text.split('\n');
    for (final label in labels) {
      final lower = label.toLowerCase();
      for (final line in lines) {
        if (line.toLowerCase().startsWith(lower)) {
          final parts = line.split(RegExp('[:|-]'));
          if (parts.length > 1) {
            return parts.sublist(1).join(':').trim();
          }
        }
      }
    }
    return null;
  }
}
