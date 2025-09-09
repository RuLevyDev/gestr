import 'dart:io';
import 'package:gestr/data/ocr/ocr_service.dart';
import 'package:gestr/domain/entities/ocr_invoice_data.dart';
import 'package:gestr/domain/repositories/ocr/ocr_repository.dart';

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

    // Búsqueda de un importe con dos decimales
    final amountMatch = RegExp(r'(\d+[\.,]\d{2})').firstMatch(rawText);
    final double? amount =
        amountMatch != null
            ? double.tryParse(amountMatch.group(1)!.replaceAll(',', '.'))
            : null;

    // Búsqueda de fecha en formato ISO
    final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(rawText);
    final DateTime? date =
        dateMatch != null ? DateTime.tryParse(dateMatch.group(1)!) : null;

    return OcrInvoiceData(title: title, amount: amount, date: date);
  }
}
