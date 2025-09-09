/// Datos estructurados obtenidos tras procesar una imagen de factura.
class OcrInvoiceData {
  final String? title;
  final double? amount;
  final DateTime? date;
  final String? issuer;
  final String? receiver;
  final String? concept;

  OcrInvoiceData({
    this.title,
    this.amount,
    this.date,
    this.issuer,
    this.receiver,
    this.concept,
  });
}
