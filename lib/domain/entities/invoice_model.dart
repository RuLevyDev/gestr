import 'dart:io';

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
  final double netAmount;
  final double iva;
  final InvoiceStatus status;
  final String? invoiceNumber;
  final String? issuer;
  final String? issuerTaxId;
  final String? issuerAddress;
  final String? receiver;
  final String? receiverTaxId;
  final String? receiverAddress;
  final String? concept;
  final double? vatRate;
  final String currency;
  final File? image; // Solo para carga
  final String? imageUrl; // Para mostrar desde la red

  Invoice({
    this.id,
    required this.title,
    required this.date,
    required this.netAmount,
    required this.iva,
    required this.status,
    this.invoiceNumber,
    this.issuer,
    this.issuerTaxId,
    this.issuerAddress,
    this.receiver,
    this.receiverTaxId,
    this.receiverAddress,
    this.concept,
    this.vatRate,
    this.currency = 'EUR',
    this.image,
    this.imageUrl,
  });

  double get total => netAmount + iva;

  Invoice copyWith({
    String? id,
    String? title,
    DateTime? date,
    double? netAmount,
    double? iva,
    InvoiceStatus? status,
    String? invoiceNumber,
    String? issuer,
    String? issuerTaxId,
    String? issuerAddress,
    String? receiver,
    String? receiverTaxId,
    String? receiverAddress,
    String? concept,
    double? vatRate,
    String? currency,
    File? image,
    String? imageUrl,
  }) {
    return Invoice(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      netAmount: netAmount ?? this.netAmount,
      iva: iva ?? this.iva,
      status: status ?? this.status,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      issuer: issuer ?? this.issuer,
      issuerTaxId: issuerTaxId ?? this.issuerTaxId,
      issuerAddress: issuerAddress ?? this.issuerAddress,
      receiver: receiver ?? this.receiver,
      receiverTaxId: receiverTaxId ?? this.receiverTaxId,
      receiverAddress: receiverAddress ?? this.receiverAddress,
      concept: concept ?? this.concept,
      vatRate: vatRate ?? this.vatRate,
      currency: currency ?? this.currency,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
