// infrastructure/firebase_self_employed_user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/domain/errors/user_profile_failures.dart';
import 'package:gestr/domain/repositories/user/self_employed_repository.dart';

class SelfEmployedRepositoryImpl implements SelfEmployedUserRepository {
  final FirebaseFirestore firestore;

  SelfEmployedRepositoryImpl({required this.firestore});

  @override
  Future<Either<UserProfileFailure, Unit>> saveUser(
    SelfEmployedUser user,
  ) async {
    try {
      await firestore.collection('users').doc(user.uid).set(user.toJson());
      return const Right(unit);
    } catch (e) {
      return Left(UnknownUserProfileFailure(e.toString()));
    }
  }

  @override
  Future<Either<UserProfileFailure, SelfEmployedUser>> getUser(
    String uid,
  ) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists) return Left(UserNotFound());
      return Right(SelfEmployedUser.fromJson(doc.data()!));
    } catch (e) {
      return Left(UnknownUserProfileFailure(e.toString()));
    }
  }
}
