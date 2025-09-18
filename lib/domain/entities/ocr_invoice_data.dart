import 'package:gestr/domain/entities/ocr_line_item.dart';

class OcrInvoiceData {
  final String? title;
  final String? invoiceNumber;
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
  final String? issuerTaxId;
  final String? issuerAddress;
  final String? receiver;
  final String? receiverTaxId;
  final String? receiverAddress;
  final String? concept;
  final List<OcrLineItem> items;

  OcrInvoiceData({
    this.title,
    this.invoiceNumber,
    this.amount,
    this.vatAmount,
    this.vatRate,
    this.totalAmount,
    this.date,
    this.issuer,
    this.issuerTaxId,
    this.issuerAddress,
    this.receiver,
    this.receiverTaxId,
    this.receiverAddress,
    this.concept,
    this.items = const [],
  });
}
