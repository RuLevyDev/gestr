abstract class AuthEvent {}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  SignInRequested(this.email, this.password);
}

class SignInWithGoogleRequested extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;

  RegisterRequested(this.email, this.password);
}

class SignOutRequested extends AuthEvent {}

class ResetPasswordRequested extends AuthEvent {
  final String email;

  ResetPasswordRequested(this.email);
}

class DeleteAccountRequested extends AuthEvent {
  final String email;
  final String password;

  DeleteAccountRequested(this.email, this.password);
}

class UpdateUsernameRequested extends AuthEvent {
  final String username;

  UpdateUsernameRequested(this.username);
}
