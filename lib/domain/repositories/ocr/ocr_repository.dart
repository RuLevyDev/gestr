import 'dart:io';
import 'package:gestr/domain/entities/ocr_invoice_data.dart';

/// Abstracción del repositorio de OCR encargado de normalizar
/// la información extraída desde una imagen.
abstract class OcrRepository {
  Future<OcrInvoiceData> extractData(File image);
}
