import 'package:gestr/data/repositories/user/auth_repository_impl.dart';
import 'package:gestr/domain/repositories/user/auth_repository.dart';
import 'package:gestr/domain/usecases/user/user_usecases.dart';
import 'package:get_it/get_it.dart';

import '../../data/services/auth_service.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Servicios
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // Repositorios
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthService>()),
  );

  // Casos de uso
  getIt.registerLazySingleton<UserUseCases>(
    () => UserUseCases(getIt<AuthRepository>()),
  );
}
