import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/core/utils/app_strings.dart';
import 'package:gestr/app/auth/bloc/auth_bloc.dart';
import 'package:gestr/app/auth/bloc/auth_event.dart';

mixin AuthViewModelMixin<T extends StatefulWidget> on State<T> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isSignUp = false;
  bool isResetPassword = false;
  bool isHoveringForgot = false;
  bool isHoveringToggle = false;

  void signIn(BuildContext context) {
    context.read<AuthBloc>().add(
      SignInRequested(
        emailController.text.trim(),
        passwordController.text.trim(),
      ),
    );
  }

  void signInWithGoogle(BuildContext context) {
    context.read<AuthBloc>().add(SignInWithGoogleRequested());
  }

  void signUp(BuildContext context) {
    context.read<AuthBloc>().add(
      RegisterRequested(
        emailController.text.trim(),
        passwordController.text.trim(),
      ),
    );
  }

  void resetPassword(BuildContext context) {
    final email = emailController.text.trim();
    if (email.isNotEmpty) {
      context.read<AuthBloc>().add(ResetPasswordRequested(email));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Strings.instance.checkEmail,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(color: Colors.black38),
          ),
          backgroundColor: Colors.transparent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Strings.instance.enterEmailToResetPass,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(color: Colors.red.shade600),
          ),
          backgroundColor: Colors.transparent,
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
