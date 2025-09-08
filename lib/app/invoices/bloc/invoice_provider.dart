import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/data/repositories/invoice/invoice_repoditory_impl.dart';
import 'package:gestr/domain/repositories/invoice/invoice_reposiroty.dart';
import 'package:gestr/domain/usecases/invoice/invoice_usecases.dart';
import 'package:gestr/domain/usecases/income/income_usecases.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvoiceProvider {
  static List<SingleChildWidget> get() {
    return [
      Provider<InvoiceRepository>(
        create:
            (context) =>
                InvoiceRepositoryImpl(context.read<FirebaseFirestore>()),
        lazy: true,
      ),
      Provider<InvoiceUseCases>(
        create: (context) => InvoiceUseCases(context.read<InvoiceRepository>()),
        lazy: true,
      ),
      BlocProvider<InvoiceBloc>(
        create: (context) {
          final userId = FirebaseAuth.instance.currentUser!.uid;
          return InvoiceBloc(
            context.read<InvoiceUseCases>(),
            context.read<IncomeUseCases>(),
            userId,
          );
        },
        lazy: true,
      ),
    ];
  }
}
