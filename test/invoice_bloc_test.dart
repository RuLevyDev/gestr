import 'package:bloc_testmate/bloc_testmate.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_event.dart';
import 'package:gestr/app/invoices/bloc/invoice_state.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:gestr/domain/repositories/invoice/invoice_reposiroty.dart';
import 'package:gestr/domain/usecases/invoice/invoice_usecases.dart';

class _FakeInvoiceRepo implements InvoiceRepository {
  final List<Invoice> list;
  _FakeInvoiceRepo(this.list);

  @override
  Future<List<Invoice>> getInvoices(String userId) async => list;
  @override
  Future<void> createInvoice(String userId, Invoice invoice) async {}
  @override
  Future<void> deleteInvoice(String userId, String invoiceId) async {}
  @override
  Future<Invoice?> getInvoiceById(String userId, String id) async => null;
  @override
  Future<void> updateInvoice(String userId, Invoice invoice) async {}
}

void main() {
  final mate = BlocTestMate<InvoiceBloc, InvoiceState>()
      .factory((get) => InvoiceBloc(get<InvoiceUseCases>(), 'user-1'));

  mate.scenario(
    'fetch invoices success',
    arrange: (get) => get.register<InvoiceUseCases>(InvoiceUseCases(_FakeInvoiceRepo(const []))),
    when: (bloc) => bloc.add(const InvoiceEvent.fetch()),
    expectStates: [isA<InvoiceLoading>(), isA<InvoiceLoaded>()],
  );
}
