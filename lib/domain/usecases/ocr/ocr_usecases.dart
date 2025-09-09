import 'dart:io';
import 'package:gestr/domain/entities/ocr_invoice_data.dart';
import 'package:gestr/domain/repositories/ocr/ocr_repository.dart';

/// Casos de uso relacionados con la extracción de datos mediante OCR.
class OcrUseCases {
  final OcrRepository _repository;

  OcrUseCases(this._repository);

  /// Procesa una imagen de [invoice] y retorna los datos estructurados.
  Future<OcrInvoiceData> parseInvoice(File image) {
    return _repository.extractData(image);
  }
}
