import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestr/domain/errors/auth_failure.dart';
import 'package:gestr/domain/repositories/user/auth_repository.dart';

class UserUseCases {
  final AuthRepository _repository;

  UserUseCases(this._repository);

  Future<Either<AuthFailure, UserCredential>> signIn({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }

  Future<Either<AuthFailure, UserCredential>> signInWithGoogle() {
    return _repository.signInWithGoogle();
  }

  Future<Either<AuthFailure, UserCredential>> createAccount({
    required String email,
    required String password,
  }) {
    return _repository.createAccount(email: email, password: password);
  }

  Future<Either<AuthFailure, Unit>> signOut() {
    return _repository.signOut();
  }

  Future<Either<AuthFailure, Unit>> resetPassword({required String email}) {
    return _repository.resetPassword(email: email);
  }

  Future<Either<AuthFailure, Unit>> updateUsername({required String userName}) {
    return _repository.updateUsername(userName: userName);
  }

  Future<Either<AuthFailure, Unit>> call({
    required String email,
    required String password,
  }) {
    return _repository.deleteAccount(email: email, password: password);
  }

  User? getCurrentUser() => _repository.getCurrentUser();

  Stream<User?> getAuthStateChanges() => _repository.authStateChanges();
}
