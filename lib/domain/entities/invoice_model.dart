import 'dart:io';

enum InvoiceStatus { pending, paid, sent, overdue }

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
  final String? issuer;
  final String? receiver;
  final String? concept;
  final File? image; // Solo para carga
  final String? imageUrl; // Para mostrar desde la red

  Invoice({
    this.id,
    required this.title,
    required this.date,
    required this.netAmount,
    required this.iva,
    required this.status,
    this.issuer,
    this.receiver,
    this.concept,
    this.image,
    this.imageUrl,
  });

  double get total => netAmount + iva;
}
