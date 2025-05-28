import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestr/domain/errors/auth_failure.dart';

abstract class AuthRepository {
  Future<Either<AuthFailure, UserCredential>> signIn({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, UserCredential>> createAccount({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, Unit>> signOut();

  Future<Either<AuthFailure, Unit>> resetPassword({required String email});

  Future<Either<AuthFailure, Unit>> updateUsername({required String userName});

  Future<Either<AuthFailure, Unit>> deleteAccount({
    required String email,
    required String password,
  });
  Future<Either<AuthFailure, UserCredential>> signInWithGoogle();
  User? getCurrentUser();

  Stream<User?> authStateChanges();
}
