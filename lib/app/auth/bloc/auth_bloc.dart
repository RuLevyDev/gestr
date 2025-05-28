import 'package:gestr/app/auth/bloc/auth_event.dart';
import 'package:gestr/app/auth/bloc/auth_state.dart';
import 'package:gestr/domain/usecases/user/user_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserUseCases useCases;

  AuthBloc(this.useCases) : super(AuthInitial()) {
    on<SignInRequested>(_onSignIn);
    on<SignInWithGoogleRequested>(_onSignInWithGoogle);
    on<RegisterRequested>(_onRegister);
    on<SignOutRequested>(_onSignOut);
    on<ResetPasswordRequested>(_onResetPassword);
    on<DeleteAccountRequested>(_onDeleteAccount);
    on<UpdateUsernameRequested>(_onUpdateUsername);
  }

  Future<void> _onSignIn(SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await useCases.signIn(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (userCredential) => emit(AuthSuccess(userCredential.user)),
    );
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await useCases.signInWithGoogle();

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (userCredential) => emit(AuthSuccess(userCredential.user)),
    );
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await useCases.createAccount(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (userCredential) => emit(AuthSuccess(userCredential.user)),
    );
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await useCases.signOut();
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(AuthInitial()),
    );
  }

  Future<void> _onResetPassword(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await useCases.resetPassword(email: event.email);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(AuthSuccess(null)),
    );
  }

  Future<void> _onDeleteAccount(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await useCases.call(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(AuthInitial()),
    );
  }

  Future<void> _onUpdateUsername(
    UpdateUsernameRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await useCases.updateUsername(userName: event.username);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(AuthSuccess(useCases.getCurrentUser())),
    );
  }
}
