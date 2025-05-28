import 'package:dartz/dartz.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/domain/errors/user_profile_failures.dart';
import 'package:gestr/domain/repositories/user/self_employed_repository.dart';

class SelfEmployedUserUseCases {
  final SelfEmployedUserRepository repository;

  SelfEmployedUserUseCases(this.repository);

  Future<Either<UserProfileFailure, Unit>> saveUser(SelfEmployedUser user) {
    return repository.saveUser(user);
  }

  Future<Either<UserProfileFailure, SelfEmployedUser>> getUser(String uid) {
    return repository.getUser(uid);
  }
}
