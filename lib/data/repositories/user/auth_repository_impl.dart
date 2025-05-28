import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestr/domain/errors/auth_failure.dart';
import 'package:gestr/data/services/auth_service.dart';
import 'package:gestr/domain/repositories/user/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;

  AuthRepositoryImpl(this.authService);

  @override
  Future<Either<AuthFailure, UserCredential>> signIn({
    required String email,
    required String password,
  }) {
    return authService.signIn(email: email, password: password);
  }

  @override
  Future<Either<AuthFailure, UserCredential>> signInWithGoogle() {
    return authService.signInWithGoogle();
  }

  @override
  Future<Either<AuthFailure, UserCredential>> createAccount({
    required String email,
    required String password,
  }) {
    return authService.createAccount(email: email, password: password);
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() {
    return authService.signOut();
  }

  @override
  Future<Either<AuthFailure, Unit>> resetPassword({required String email}) {
    return authService.resetPassword(email: email);
  }

  @override
  Future<Either<AuthFailure, Unit>> updateUsername({required String userName}) {
    return authService.updateUsername(userName: userName);
  }

  @override
  Future<Either<AuthFailure, Unit>> deleteAccount({
    required String email,
    required String password,
  }) {
    return authService.deleteAccount(email: email, password: password);
  }

  @override
  User? getCurrentUser() {
    return authService.currentUser;
  }

  @override
  Stream<User?> authStateChanges() {
    return authService.authStateChanges;
  }
}
