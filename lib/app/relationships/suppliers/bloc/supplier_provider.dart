import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/relationships/suppliers/bloc/supplier_bloc.dart';
import 'package:gestr/data/repositories/supplier/supplier_repository_impl.dart';
import 'package:gestr/domain/repositories/supplier/supplier_repository.dart';
import 'package:gestr/domain/usecases/supplier/supplier_usecases.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupplierProvider {
  static List<SingleChildWidget> get() {
    return [
      Provider<SupplierRepository>(
        create:
            (context) =>
                SupplierRepositoryImpl(context.read<FirebaseFirestore>()),
        lazy: true,
      ),
      Provider<SupplierUseCases>(
        create:
            (context) => SupplierUseCases(context.read<SupplierRepository>()),
        lazy: true,
      ),
      BlocProvider<SupplierBloc>(
        create: (context) {
          final userId = FirebaseAuth.instance.currentUser!.uid;
          return SupplierBloc(context.read<SupplierUseCases>(), userId);
        },
        lazy: true,
      ),
    ];
  }
}
