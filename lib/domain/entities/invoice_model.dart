import 'dart:io';

class TaxLine {
  final double rate; // 0.00-1.00 (p.ej., 0.21)
  final double base;
  final double quota; // IVA (cuota)
  final double? recargoEquivalencia; // opcional

  const TaxLine({
    required this.rate,
    required this.base,
    required this.quota,
    this.recargoEquivalencia,
  });
}

enum InvoiceStatus { pending, paid, sent, overdue, paidByMe }

extension InvoiceStatusExtension on InvoiceStatus {
  String get name {
    switch (this) {
      case InvoiceStatus.pending:
        return 'pending';
      case InvoiceStatus.paid:
        return 'paid';
      case InvoiceStatus.sent:
        return 'sent';
      case InvoiceStatus.overdue:
        return 'overdue';
      case InvoiceStatus.paidByMe:
        return 'paidByMe';
    }
  }
}

extension InvoiceStatusTranslation on InvoiceStatus {
  String get labelEs {
    switch (this) {
      case InvoiceStatus.paid:
        return 'pagada';
      case InvoiceStatus.pending:
        return 'pendiente';
      case InvoiceStatus.sent:
        return 'enviada';
      case InvoiceStatus.overdue:
        return 'vencida';
      case InvoiceStatus.paidByMe:
        return 'pagada por mí';
    }
  }
}

class Invoice {
  final String? id;
  final String title;
  final DateTime date;
  final DateTime? operationDate; // fecha de operación SII
  final double netAmount;
  final double iva;
  final InvoiceStatus status;
  final String? invoiceNumber;
  final String? series; // serie para numeración
  final int? sequentialNumber; // número dentro de la serie
  final String? issuer;
  final String? issuerTaxId;
  final String? issuerAddress;
  final String? receiver;
  final String? receiverTaxId;
  final String? receiverAddress;
  final String? concept;
  final double? vatRate;
  final String currency;
  final String? direction; // 'issued' | 'received'
  final List<TaxLine>? taxLines; // desglose SII
  final bool? reverseCharge; // inversión del sujeto pasivo
  final String? exemptionType; // clave exención (E1..E6)
  final String? specialRegime; // RECC/Agencias/etc.
  final File? image; // Solo para carga
  final String? imageUrl; // Para mostrar desde la red

  Invoice({
    this.id,
    required this.title,
    required this.date,
    this.operationDate,
    required this.netAmount,
    required this.iva,
    required this.status,
    this.invoiceNumber,
    this.series,
    this.sequentialNumber,
    this.issuer,
    this.issuerTaxId,
    this.issuerAddress,
    this.receiver,
    this.receiverTaxId,
    this.receiverAddress,
    this.concept,
    this.vatRate,
    this.currency = 'EUR',
    this.direction,
    this.taxLines,
    this.reverseCharge,
    this.exemptionType,
    this.specialRegime,
    this.image,
    this.imageUrl,
  });

  double get total => netAmount + iva;

  Invoice copyWith({
    String? id,
    String? title,
    DateTime? date,
    DateTime? operationDate,
    double? netAmount,
    double? iva,
    InvoiceStatus? status,
    String? invoiceNumber,
    String? series,
    int? sequentialNumber,
    String? issuer,
    String? issuerTaxId,
    String? issuerAddress,
    String? receiver,
    String? receiverTaxId,
    String? receiverAddress,
    String? concept,
    double? vatRate,
    String? currency,
    String? direction,
    List<TaxLine>? taxLines,
    bool? reverseCharge,
    String? exemptionType,
    String? specialRegime,
    File? image,
    String? imageUrl,
  }) {
    return Invoice(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      operationDate: operationDate ?? this.operationDate,
      netAmount: netAmount ?? this.netAmount,
      iva: iva ?? this.iva,
      status: status ?? this.status,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      series: series ?? this.series,
      sequentialNumber: sequentialNumber ?? this.sequentialNumber,
      issuer: issuer ?? this.issuer,
      issuerTaxId: issuerTaxId ?? this.issuerTaxId,
      issuerAddress: issuerAddress ?? this.issuerAddress,
      receiver: receiver ?? this.receiver,
      receiverTaxId: receiverTaxId ?? this.receiverTaxId,
      receiverAddress: receiverAddress ?? this.receiverAddress,
      concept: concept ?? this.concept,
      vatRate: vatRate ?? this.vatRate,
      currency: currency ?? this.currency,
      direction: direction ?? this.direction,
      taxLines: taxLines ?? this.taxLines,
      reverseCharge: reverseCharge ?? this.reverseCharge,
      exemptionType: exemptionType ?? this.exemptionType,
      specialRegime: specialRegime ?? this.specialRegime,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
