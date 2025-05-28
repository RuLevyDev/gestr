import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/core/utils/animate_background.dart';

import 'package:gestr/app/auth/bloc/auth_bloc.dart';

import 'package:gestr/app/auth/bloc/auth_state.dart';
import 'package:gestr/app/auth/application/viewmodels/auth_viewmodel.dart';
import 'package:gestr/core/utils/app_strings.dart';
import 'package:gestr/core/utils/images.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> with AuthViewModelMixin {
  @override
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Visibility(
          visible: isResetPassword,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSecondary),
            onPressed: () => setState(() => isResetPassword = false),
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(color: Colors.white.withValues(alpha: 0.1)),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 600;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 500 : double.infinity,
                    ),
                    child: BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is AuthFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                state.message,
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(color: Colors.red.shade600),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          );
                        } else if (state is AuthSuccess) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: 80,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isSignUp
                                  ? Strings.instance.createAccount
                                  : Strings.instance.welcomeBack,
                              style: textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSignUp
                                  ? Strings.instance.signUpDetails
                                  : Strings.instance.loginDetails,
                              style: textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () => signInWithGoogle(context),
                              icon: Images.googleLogoSvg,
                              label: Text(
                                isSignUp
                                    ? Strings.instance.signUpWithGoogle
                                    : Strings.instance.loginWithGoogle,
                                style: textTheme.titleSmall?.copyWith(
                                  color: colorScheme.surface,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(thickness: 1),
                            const SizedBox(height: 24),
                            TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email),
                                hintText: Strings.instance.emailHint,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Visibility(
                              visible: !isResetPassword,
                              maintainAnimation: true,
                              maintainSize: true,
                              maintainState: true,
                              child: TextField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock),
                                  hintText: Strings.instance.passwordHint,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Visibility(
                                maintainAnimation: true,
                                maintainSize: true,
                                maintainState: true,
                                visible: !isSignUp && !isResetPassword,
                                child: MouseRegion(
                                  onEnter: (_) {
                                    if (kIsWeb) {
                                      setState(() => isHoveringForgot = true);
                                    }
                                  },
                                  onExit: (_) {
                                    if (kIsWeb) {
                                      setState(() => isHoveringForgot = false);
                                    }
                                  },
                                  cursor:
                                      kIsWeb
                                          ? SystemMouseCursors.click
                                          : MouseCursor.defer,
                                  child: InkWell(
                                    onTap:
                                        () => setState(
                                          () => isResetPassword = true,
                                        ),
                                    child: Text(
                                      Strings.instance.forgotPassword,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color:
                                            isHoveringForgot
                                                ? colorScheme.primary
                                                : colorScheme.surface,
                                        // decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (isResetPassword) {
                                  resetPassword(context);
                                } else if (isSignUp) {
                                  signUp(context);
                                } else {
                                  signIn(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isSignUp
                                    ? Strings.instance.signUpButton
                                    : isResetPassword
                                    ? Strings.instance.resetPasswordButton
                                    : Strings.instance.loginButton,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Visibility(
                              maintainAnimation: true,
                              maintainSize: true,
                              maintainState: true,
                              visible: !isResetPassword,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isSignUp
                                        ? Strings.instance.alreadyHaveAccount
                                        : Strings.instance.dontHaveAccount,
                                    style: textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 4),
                                  MouseRegion(
                                    onEnter: (_) {
                                      if (kIsWeb) {
                                        setState(() => isHoveringToggle = true);
                                      }
                                    },
                                    onExit: (_) {
                                      if (kIsWeb) {
                                        setState(
                                          () => isHoveringToggle = false,
                                        );
                                      }
                                    },
                                    cursor:
                                        kIsWeb
                                            ? SystemMouseCursors.click
                                            : MouseCursor.defer,
                                    child: InkWell(
                                      onTap:
                                          () => setState(
                                            () => isSignUp = !isSignUp,
                                          ),
                                      child: Text(
                                        isSignUp
                                            ? Strings.instance.loginButton
                                            : Strings.instance.signUpButton,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color:
                                              isHoveringToggle
                                                  ? colorScheme.primary
                                                  : colorScheme.surface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
