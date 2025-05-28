import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/data/repositories/fixedpayments/fixed_payments_repository_impl.dart';
import 'package:gestr/domain/repositories/fixedpayments/fixed_payments_repository.dart';
import 'package:gestr/domain/usecases/fixed_payments_usecases.dart/fixed_payment_usecases.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class FixedPaymentProvider {
  static List<SingleChildWidget> get() {
    return [
      Provider<FixedPaymentRepository>(
        create:
            (context) =>
                FixedPaymentRepositoryImpl(context.read<FirebaseFirestore>()),
        lazy: true,
      ),
      Provider<FixedPaymentUseCases>(
        create:
            (context) =>
                FixedPaymentUseCases(context.read<FixedPaymentRepository>()),
        lazy: true,
      ),
      BlocProvider<FixedPaymentBloc>(
        create: (context) {
          final userId = FirebaseAuth.instance.currentUser!.uid;
          return FixedPaymentBloc(context.read<FixedPaymentUseCases>(), userId);
        },
        lazy: true,
      ),
    ];
  }
}
