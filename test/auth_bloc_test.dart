import 'package:bloc_testmate/bloc_testmate.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestr/app/auth/bloc/auth_bloc.dart';
import 'package:gestr/app/auth/bloc/auth_event.dart';
import 'package:gestr/app/auth/bloc/auth_state.dart';
import 'package:gestr/domain/errors/auth_failure.dart' as auth_err;
import 'package:gestr/domain/repositories/user/auth_repository.dart';
import 'package:gestr/domain/usecases/user/user_usecases.dart';

class _FakeAuthRepo implements AuthRepository {
  final bool ok;
  _FakeAuthRepo(this.ok);

  @override
  Future<Either<auth_err.AuthFailure, Unit>> signOut() async =>
      ok ? const Right(unit) : Left(auth_err.UnknownAuthFailure('fail'));

  // Métodos no usados en estos tests
  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();
  @override
  getCurrentUser() => null;
  @override
  Future<Either<auth_err.AuthFailure, UserCredential>> createAccount({
    required String email,
    required String password,
  }) async => Left(auth_err.UnknownAuthFailure('unused'));
  @override
  Future<Either<auth_err.AuthFailure, Unit>> deleteAccount({
    required String email,
    required String password,
  }) async => const Right(unit);
  @override
  Future<Either<auth_err.AuthFailure, Unit>> resetPassword({
    required String email,
  }) async => const Right(unit);
  @override
  Future<Either<auth_err.AuthFailure, UserCredential>> signIn({
    required String email,
    required String password,
  }) async => Left(auth_err.UnknownAuthFailure('unused'));
  @override
  Future<Either<auth_err.AuthFailure, UserCredential>>
  signInWithGoogle() async => Left(auth_err.UnknownAuthFailure('unused'));
  @override
  Future<Either<auth_err.AuthFailure, Unit>> updateUsername({
    required String userName,
  }) async => const Right(unit);
}

void main() {
  final mate = BlocTestMate<AuthBloc, AuthState>().factory(
    (get) => AuthBloc(get<UserUseCases>()),
  );

  mate.scenario(
    'sign out success',
    arrange:
        (get) => get.register<UserUseCases>(UserUseCases(_FakeAuthRepo(true))),
    when: (bloc) => bloc.add(SignOutRequested()),
    expectStates: [isA<AuthLoading>(), isA<AuthInitial>()],
  );

  mate.scenario(
    'sign out error',
    arrange:
        (get) => get.register<UserUseCases>(UserUseCases(_FakeAuthRepo(false))),
    when: (bloc) => bloc.add(SignOutRequested()),
    expectStates: [isA<AuthLoading>(), isA<AuthFailure>()],
  );
}
