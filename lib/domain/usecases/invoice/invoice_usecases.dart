import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:gestr/domain/repositories/invoice/invoice_reposiroty.dart';

class InvoiceUseCases {
  final InvoiceRepository _invoiceRepository;

  InvoiceUseCases(this._invoiceRepository);

  Future<List<Invoice>> fetchInvoices(String userId) {
    return _invoiceRepository.getInvoices(userId);
  }

  Future<void> createInvoice(String userId, Invoice invoice) {
    return _invoiceRepository.createInvoice(userId, invoice);
  }

  Future<Invoice> voidInvoice(
    String userId,
    String invoiceId, {
    String? voidedBy,
    String? voidReason,
  }) {
    return _invoiceRepository.voidInvoice(
      userId,
      invoiceId,
      voidedBy: voidedBy,
      voidReason: voidReason,
    );
  }

  Future<void> updateInvoice(String userId, Invoice invoice) {
    return _invoiceRepository.updateInvoice(userId, invoice);
  }

  Future<Invoice?> getInvoiceById(String userId, String id) {
    return _invoiceRepository.getInvoiceById(userId, id);
  }
}
