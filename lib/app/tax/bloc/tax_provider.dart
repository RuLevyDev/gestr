import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:gestr/app/tax/bloc/vat/vat_bloc.dart';
import 'package:gestr/app/tax/bloc/top_clients/top_clients_bloc.dart';
import 'package:gestr/app/tax/bloc/pre303/pre303_bloc.dart';
import 'package:gestr/app/tax/bloc/expenses_by_category/expenses_by_category_bloc.dart';
import 'package:gestr/app/tax/bloc/summary/summary_bloc.dart';
import 'package:gestr/app/tax/bloc/chart/chart_bloc.dart';
import 'package:gestr/data/repositories/tax/tax_summary_repository_impl.dart';
import 'package:gestr/domain/repositories/fixedpayments/fixed_payments_repository.dart';
import 'package:gestr/domain/repositories/invoice/invoice_reposiroty.dart';
import 'package:gestr/domain/repositories/tax/tax_summary_repository.dart';
import 'package:gestr/domain/usecases/tax/tax_summary_usecases.dart';

class TaxProvider {
  static List<SingleChildWidget> get() {
    return [
      // Repositorio de TaxSummary calculado a partir de invoices y pagos fijos
      Provider<TaxSummaryRepository>(
        create: (context) => TaxSummaryRepositoryImpl(
          context.read<InvoiceRepository>(),
          context.read<FixedPaymentRepository>(),
        ),
        lazy: true,
      ),
      // Casos de uso
      Provider<TaxSummaryUseCases>(
        create: (context) =>
            TaxSummaryUseCases(context.read<TaxSummaryRepository>()),
        lazy: true,
      ),
      BlocProvider<SummaryBloc>(
        create: (context) => SummaryBloc(
          context.read<TaxSummaryUseCases>(),
          FirebaseAuth.instance.currentUser!.uid,
        ),
        lazy: true,
      ),
      BlocProvider<ChartBloc>(
        create: (context) => ChartBloc(
          context.read<TaxSummaryUseCases>(),
          FirebaseAuth.instance.currentUser!.uid,
        ),
        lazy: true,
      ),
      BlocProvider<VatBloc>(
        create: (context) =>
            VatBloc(context.read<TaxSummaryUseCases>(), FirebaseAuth.instance.currentUser!.uid),
        lazy: true,
      ),
      BlocProvider<ExpensesByCategoryBloc>(
        create: (context) => ExpensesByCategoryBloc(
          context.read<TaxSummaryUseCases>(),
          FirebaseAuth.instance.currentUser!.uid,
        ),
        lazy: true,
      ),
      BlocProvider<TopClientsBloc>(
        create: (context) =>
            TopClientsBloc(context.read<TaxSummaryUseCases>(), FirebaseAuth.instance.currentUser!.uid),
        lazy: true,
      ),
      BlocProvider<Pre303Bloc>(
        create: (context) =>
            Pre303Bloc(context.read<TaxSummaryUseCases>(), FirebaseAuth.instance.currentUser!.uid),
        lazy: true,
      ),
    ];
  }
}
