import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/incomes/bloc/income_bloc.dart';
import 'package:gestr/domain/repositories/income/income_repository.dart';
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
      BlocProvider<IncomeBloc>(
        create: (context) {
          final userId = FirebaseAuth.instance.currentUser!.uid;
          return IncomeBloc(context.read<IncomeUseCases>(), userId);
        },
        lazy: true,
      ),
    ];
  }
}
