import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/clients/bloc/client_bloc.dart';
import 'package:gestr/data/repositories/client/client_repository_impl.dart';
import 'package:gestr/domain/repositories/client/client_repository.dart';
import 'package:gestr/domain/usecases/client/client_usecases.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientProvider {
  static List<SingleChildWidget> get() {
    return [
      Provider<ClientRepository>(
        create:
            (context) =>
                ClientRepositoryImpl(context.read<FirebaseFirestore>()),
        lazy: true,
      ),
      Provider<ClientUseCases>(
        create: (context) => ClientUseCases(context.read<ClientRepository>()),
        lazy: true,
      ),
      BlocProvider<ClientBloc>(
        create: (context) {
          final userId = FirebaseAuth.instance.currentUser!.uid;
          return ClientBloc(context.read<ClientUseCases>(), userId);
        },
        lazy: true,
      ),
    ];
  }
}
