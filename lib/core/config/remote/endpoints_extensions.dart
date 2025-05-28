import 'package:gestr/core/config/remote/endpoints.dart';

extension UserEndpoints on Endpoints {
  String get userLogin => '$endpoint/user/login';
  String get userRegister => '$endpoint/user/register';
  String get userLogout => '$endpoint/user/logout';
  String get userProfile => '$endpoint/user/profile';
  String get userUpdate => '$endpoint/user/update';
  String get userDelete => '$endpoint/user/delete';
}
