//  ( -_•)▄︻テحكـ━一:bum:
import 'package:easy_localization/easy_localization.dart';

class Strings {
  Strings._();
  static final instance = Strings._();

  // AuthPage
  String get createAccount => tr("authPage.createAccount");
  String get welcomeBack => tr("authPage.welcomeBack");
  String get signUpDetails => tr("authPage.signUpDetails");
  String get loginDetails => tr("authPage.loginDetails");
  String get signUpWithGoogle => tr("authPage.signUpWithGoogle");
  String get loginWithGoogle => tr("authPage.loginWithGoogle");
  String get forgotPassword => tr("authPage.forgotPassword");
  String get signUpButton => tr("authPage.signUpButton");
  String get resetPasswordButton => tr("authPage.resetPasswordButton");
  String get loginButton => tr("authPage.loginButton");
  String get alreadyHaveAccount => tr("authPage.alreadyHaveAccount");
  String get dontHaveAccount => tr("authPage.dontHaveAccount");
  String get signUpLink => tr("authPage.signUpLink");
  String get loginLink => tr("authPage.loginLink");
  String get emailHint => tr("authPage.emailHint");
  String get passwordHint => tr("authPage.passwordHint");
  String get checkEmail => tr("general.authPage.checkEmail");
  String get enterEmailToResetPass =>
      tr("general.authPage.enterEmailToResetPass");

  // UnknownRoutePage
  String get unknownRouteTitle => tr("unknownRoutePage.appBarTitle");
  String get unknownRouteBody => tr("unknownRoutePage.bodyText");

  // AuthFailure
  String get emailAlreadyInUse => tr("authFailure.emailAlreadyInUse");
  String get invalidCredentials => tr("authFailure.invalidCredentials");
  String get userNotFound => tr("authFailure.userNotFound");
  String get unknownAuthFailure => tr("authFailure.unknownAuthFailure");
  String get cancelledByUser => tr("authFailure.cancelledByUser");
}
