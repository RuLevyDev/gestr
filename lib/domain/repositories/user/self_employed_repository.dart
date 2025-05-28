import 'package:dartz/dartz.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/domain/errors/user_profile_failures.dart';

abstract class SelfEmployedUserRepository {
  Future<Either<UserProfileFailure, Unit>> saveUser(SelfEmployedUser user);
  Future<Either<UserProfileFailure, SelfEmployedUser>> getUser(String uid);
}
