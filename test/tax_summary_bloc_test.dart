import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_testmate/bloc_testmate.dart';
import 'package:gestr/app/tax/bloc/tax_summary_bloc.dart';
import 'package:gestr/app/tax/bloc/tax_summary_event.dart';
import 'package:gestr/app/tax/bloc/tax_summary_state.dart';
import 'package:gestr/domain/entities/tax_summary_model.dart';
import 'package:gestr/domain/entities/tax_vat_breakdown.dart';
import 'package:gestr/domain/entities/tax_client_total.dart';
import 'package:gestr/domain/entities/tax_pre303.dart';
import 'package:gestr/domain/entities/tax_category_total.dart';
import 'package:gestr/domain/repositories/tax/tax_summary_repository.dart';
import 'package:gestr/domain/usecases/tax/tax_summary_usecases.dart';

class _FakeTaxRepo implements TaxSummaryRepository {
  final bool throwOnSummary;
  _FakeTaxRepo({this.throwOnSummary = false});

  @override
  Future<TaxSummary> getSummary(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    if (throwOnSummary) throw Exception('boom');
    return const TaxSummary(
      totalIncome: 100,
      totalExpenses: 40,
      vatCollected: 21,
      vatPaid: 5,
      invoiceCount: 2,
      averageTicket: 50,
    );
  }

  @override
  Future<VatBreakdown> getVatBreakdown(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    return const VatBreakdown(base21: 100, iva21: 21);
  }

  @override
  Future<List<ClientTotal>> getTopClients(
    String userId, {
    DateTime? start,
    DateTime? end,
    int limit = 5,
  }) async {
    return const [ClientTotal(client: 'Acme', total: 100)];
  }

  @override
  Future<Pre303Summary> getPre303(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    return const Pre303Summary(
      base21: 100,
      iva21: 21,
      totalDevengadoBase: 100,
      totalDevengadoIva: 21,
      totalSoportadoIva: 5,
      prorrata: 1.0,
      soportadoAjustado: 5,
    );
  }

  @override
  Future<List<CategoryTotal>> getExpensesByCategory(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    return const [];
  }
}

void main() {
  final mate = BlocTestMate<TaxSummaryBloc, TaxSummaryState>().factory(
    (get) => TaxSummaryBloc(get<TaxSummaryUseCases>(), 'user-1'),
  );

  mate.scenario(
    'fetch success emits Loading then Loaded',
    arrange: (get) {
      get.register<TaxSummaryUseCases>(TaxSummaryUseCases(_FakeTaxRepo()));
    },
    when: (bloc) => bloc.add(const TaxSummaryEvent.fetch()),
    wait: const Duration(milliseconds: 10),
    expectStates: [isA<TaxSummaryLoading>(), isA<TaxSummaryLoaded>()],
  );

  mate.scenario(
    'fetch error emits Loading then Error',
    arrange: (get) {
      get.register<TaxSummaryUseCases>(
        TaxSummaryUseCases(_FakeTaxRepo(throwOnSummary: true)),
      );
    },
    when: (bloc) => bloc.add(const TaxSummaryEvent.fetch()),
    wait: const Duration(milliseconds: 10),
    expectStates: [isA<TaxSummaryLoading>(), isA<TaxSummaryError>()],
  );
}
