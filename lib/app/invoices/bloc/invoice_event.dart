import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/invoice_model.dart';

enum InvoiceEventType { fetch, refresh, create, delete, getById, update }

class InvoiceEvent extends Equatable {
  final InvoiceEventType type;
  final Invoice? invoice;
  final String? invoiceId;
  final String? voidReason;

  const InvoiceEvent._(
    this.type, {
    this.invoice,
    this.invoiceId,
    this.voidReason,
  });
  const InvoiceEvent.getById(String invoiceId)
    : this._(InvoiceEventType.getById, invoiceId: invoiceId);

  const InvoiceEvent.fetch() : this._(InvoiceEventType.fetch);
  const InvoiceEvent.refresh() : this._(InvoiceEventType.refresh);
  const InvoiceEvent.create(Invoice invoice)
    : this._(InvoiceEventType.create, invoice: invoice);
  const InvoiceEvent.delete(String invoiceId, {String? voidReason})
    : this._(
        InvoiceEventType.delete,
        invoiceId: invoiceId,
        voidReason: voidReason,
      );
  const InvoiceEvent.update(Invoice invoice)
    : this._(InvoiceEventType.update, invoice: invoice);

  @override
  List<Object?> get props => [type, invoice, invoiceId, voidReason];
}
