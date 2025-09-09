import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/incomes/bloc/bank_transaction_bloc.dart';
import 'package:gestr/app/incomes/bloc/income_bloc.dart';
import 'package:gestr/data/banking/bank_service.dart';
import 'package:gestr/data/repositories/banking/bank_repository_impl.dart';
import 'package:gestr/domain/repositories/banking/bank_repository.dart';
import 'package:gestr/domain/repositories/income/income_repository.dart';
import 'package:gestr/domain/usecases/banking/bank_usecases.dart';
import 'package:gestr/domain/usecases/income/income_usecases.dart';
import 'package:gestr/data/repositories/income/income_repository_impl.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomeProvider {
  static List<SingleChildWidget> get() {
    return [
      Provider<IncomeRepository>(
        create:
            (context) =>
                IncomeRepositoryImpl(context.read<FirebaseFirestore>()),
        lazy: true,
      ),
      Provider<IncomeUseCases>(
        create: (context) => IncomeUseCases(context.read<IncomeRepository>()),
        lazy: true,
      ),
      Provider<BankService>(create: (_) => BankService(), lazy: true),
      Provider<BankRepository>(
        create: (context) => BankRepositoryImpl(context.read<BankService>()),
        lazy: true,
      ),
      Provider<BankUseCases>(
        create: (context) => BankUseCases(context.read<BankRepository>()),
        lazy: true,
      ),
      BlocProvider<IncomeBloc>(
        create: (context) {
          final userId = FirebaseAuth.instance.currentUser!.uid;
          return IncomeBloc(context.read<IncomeUseCases>(), userId);
        },
        lazy: true,
      ),
      BlocProvider<BankTransactionBloc>(
        create: (context) {
          final userId = FirebaseAuth.instance.currentUser!.uid;
          return BankTransactionBloc(context.read<BankUseCases>(), userId);
        },
        lazy: true,
      ),
    ];
  }
}
