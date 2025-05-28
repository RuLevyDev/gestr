import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import '../../domain/errors/auth_failure.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'dart:io' show Platform;

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

/// Servicio de autenticación que encapsula todas las operaciones
/// relacionadas con [FirebaseAuth] y las adapta al patrón funcional
/// usando `Either<Failure, Result>`.
class AuthService {
  /// Instancia única de FirebaseAuth utilizada en toda la app.
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  /// Obtiene el usuario actualmente autenticado, o `null` si no hay sesión activa.
  User? get currentUser => firebaseAuth.currentUser;

  /// Stream que notifica los cambios en el estado de autenticación.
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  /// Inicia sesión con correo y contraseña.
  ///
  /// Retorna un [Right] con [UserCredential] si es exitoso,
  /// o un [Left] con [AuthFailure] si ocurre un error.
  Future<Either<AuthFailure, UserCredential>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('SignIn error: ${e.code}');
      return Left(_mapFirebaseErrorToFailure(e));
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  /// Inicia sesión con Google.
  ///
  /// Retorna un [Right] con [UserCredential] si es exitoso,
  /// o un [Left] con [AuthFailure] si ocurre un error.
  Future<Either<AuthFailure, UserCredential>> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Flujo específico para la Web
        final googleProvider = GoogleAuthProvider();

        final userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
        return Right(userCredential);
      } else {
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();

        // El usuario canceló manualmente el flujo
        if (googleUser == null) {
          return Left(CancelledByUser());
        }

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        return Right(userCredential);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('GoogleSignIn error: ${e.code}');
      return Left(_mapFirebaseErrorToFailure(e));
    } catch (e) {
      debugPrint('Unexpected GoogleSignIn error: $e');
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  /// Crea una cuenta con correo y contraseña.
  ///
  /// Retorna un [Right] con [UserCredential] si es exitoso,
  /// o un [Left] con [AuthFailure] si falla.
  Future<Either<AuthFailure, UserCredential>> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('CreateAccount error: ${e.code}');
      return Left(_mapFirebaseErrorToFailure(e));
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  /// Cierra la sesión del usuario actual.
  ///
  /// Retorna [Right.unit] si es exitoso, o un [Left] con [AuthFailure] si falla.
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await firebaseAuth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  /// Envía un correo para restablecer la contraseña.
  ///
  /// Retorna [Right.unit] si es exitoso, o un [Left] con [AuthFailure] si falla.
  Future<Either<AuthFailure, Unit>> resetPassword({
    required String email,
  }) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseErrorToFailure(e));
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  /// Actualiza el nombre visible del usuario actual.
  ///
  /// Retorna [Right.unit] si es exitoso, o un [Left] con [AuthFailure] si falla.
  Future<Either<AuthFailure, Unit>> updateUsername({
    required String userName,
  }) async {
    try {
      await currentUser?.updateDisplayName(userName);
      return const Right(unit);
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  /// Elimina permanentemente la cuenta del usuario actual.
  ///
  /// Se requiere reautenticación con email y password.
  /// Retorna [Right.unit] si es exitoso, o un [Left] con [AuthFailure] si falla.
  Future<Either<AuthFailure, Unit>> deleteAccount({
    required String email,
    required String password,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return Left(InvalidCredentials());
      }

      // Crear credenciales para reautenticación
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Reautenticación requerida antes de eliminar
      await user.reauthenticateWithCredential(credential);

      // Si la reautenticación es exitosa, elimina la cuenta
      await user.delete();

      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      debugPrint('DeleteAccount error: ${e.code}');
      return Left(_mapFirebaseErrorToFailure(e));
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  /// Mapea un error de Firebase a un tipo de [AuthFailure] definido en el dominio.
  AuthFailure _mapFirebaseErrorToFailure(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return EmailAlreadyInUse();
      case 'user-not-found':
      case 'wrong-password':
        return InvalidCredentials();
      default:
        return UnknownAuthFailure(e.message ?? 'Error desconocido');
    }
  }
}
