import 'package:gestr/domain/entities/invoice_model.dart';

abstract class InvoiceRepository {
  Future<List<Invoice>> getInvoices(String userId);
  Future<void> createInvoice(String userId, Invoice invoice);
  Future<void> deleteInvoice(String userId, String invoiceId);
  Future<void> updateInvoice(String userId, Invoice invoice);
  Future<Invoice?> getInvoiceById(String userId, String id);
}
