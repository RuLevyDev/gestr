import 'package:gestr/domain/entities/ocr_line_item.dart';

class OcrInvoiceData {
  final String? title;
  // Base imponible (neto)
  final double? amount;
  // IVA en euros, si se detecta
  final double? vatAmount;
  // Porcentaje de IVA (ej. 21.0 para 21%)
  final double? vatRate;
  // Total con IVA, si se detecta
  final double? totalAmount;
  final DateTime? date;
  final String? issuer;
  final String? receiver;
  final String? concept;
  final List<OcrLineItem> items;

  OcrInvoiceData({
    this.title,
    this.amount,
    this.vatAmount,
    this.vatRate,
    this.totalAmount,
    this.date,
    this.issuer,
    this.receiver,
    this.concept,
    this.items = const [],
  });
}
