import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/data/repositories/user/self_employed_repository_impl.dart';
import 'package:gestr/domain/repositories/user/self_employed_repository.dart';
import 'package:gestr/domain/usecases/user/self_employed_user_usecases.dart';
import 'package:gestr/app/auth/bloc/auth_bloc.dart';
import 'package:gestr/data/repositories/user/auth_repository_impl.dart';
import 'package:gestr/data/services/auth_service.dart';
import 'package:gestr/domain/repositories/user/auth_repository.dart';
import 'package:gestr/domain/usecases/user/user_usecases.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class UserProvider {
  static List<SingleChildWidget> get() {
    return [
      // 👇 Proveedor de Auth
      Provider<AuthService>(create: (context) => AuthService(), lazy: true),
      Provider<AuthRepository>(
        create: (context) => AuthRepositoryImpl(context.read<AuthService>()),
        lazy: true,
      ),
      Provider<UserUseCases>(
        create: (context) => UserUseCases(context.read<AuthRepository>()),
        lazy: true,
      ),
      BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(context.read<UserUseCases>()),
        lazy: true,
      ),

      // 👇 Proveedor de Firestore
      Provider<FirebaseFirestore>(create: (_) => FirebaseFirestore.instance),

      // 👇 Repositorio y casos de uso del autónomo
      Provider<SelfEmployedUserRepository>(
        create:
            (context) => SelfEmployedRepositoryImpl(
              firestore: context.read<FirebaseFirestore>(),
            ),
        lazy: true,
      ),
      Provider<SelfEmployedUserUseCases>(
        create:
            (context) => SelfEmployedUserUseCases(
              context.read<SelfEmployedUserRepository>(),
            ),
        lazy: true,
      ),
    ];
  }
}
