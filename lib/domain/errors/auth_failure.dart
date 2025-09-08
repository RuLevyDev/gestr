import 'package:gestr/core/utils/app_strings.dart';

/// Representa un fallo relacionado con la autenticación.
///
/// Esta clase base permite definir diferentes tipos de errores específicos
/// para ser manejados de forma explícita en la capa de dominio/presentación.
abstract class AuthFailure {
  /// Mensaje legible para mostrar al usuario o para logging.
  final String message;

  const AuthFailure(this.message);
}

/// El email ya está registrado por otro usuario.
class EmailAlreadyInUse extends AuthFailure {
  EmailAlreadyInUse() : super(Strings.instance.emailAlreadyInUse);
}

/// El usuario no fue encontrado o la contraseña es incorrecta.
class InvalidCredentials extends AuthFailure {
  InvalidCredentials() : super(Strings.instance.invalidCredentials);
}

/// El usuario no existe en el sistema.
class UserNotFound extends AuthFailure {
  UserNotFound() : super(Strings.instance.userNotFound);
}

/// Falla desconocida o no clasificada de autenticación.
class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure(super.message);
}

/// El usuario canceló manualmente el inicio de sesión (por ejemplo, en Google Sign-In).
class CancelledByUser extends AuthFailure {
  CancelledByUser() : super(Strings.instance.cancelledByUser);
}
