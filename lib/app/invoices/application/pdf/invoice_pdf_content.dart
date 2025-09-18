import 'dart:typed_data';

import 'package:gestr/domain/entities/invoice_model.dart';

class InvoicePdfContent {
  const InvoicePdfContent({
    required this.title,
    required this.issueDate,
    required this.netAmount,
    required this.ivaAmount,
    required this.status,
    this.invoiceNumber,
    this.issuerName,
    this.issuerTaxId,
    this.issuerAddress,
    this.receiverName,
    this.receiverTaxId,
    this.receiverAddress,
    this.concept,
    this.currency = 'EUR',
    this.vatRate,
    this.attachmentImageBytes,
  });

  final String title;
  final DateTime issueDate;
  final double netAmount;
  final double ivaAmount;
  final InvoiceStatus status;
  final String? invoiceNumber;
  final String? issuerName;
  final String? issuerTaxId;
  final String? issuerAddress;
  final String? receiverName;
  final String? receiverTaxId;
  final String? receiverAddress;
  final String? concept;
  final String currency;
  final double? vatRate;
  final Uint8List? attachmentImageBytes;

  double get total => netAmount + ivaAmount;
}
