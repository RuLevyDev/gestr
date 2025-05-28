abstract class UserProfileFailure {
  const UserProfileFailure();
}

class UserNotFound extends UserProfileFailure {
  const UserNotFound();

  @override
  String toString() => 'User not found';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserNotFound;

  @override
  int get hashCode => runtimeType.hashCode;
}

class UnknownUserProfileFailure extends UserProfileFailure {
  final String message;

  const UnknownUserProfileFailure(this.message);

  @override
  String toString() => 'UnknownUserProfileFailure: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnknownUserProfileFailure && message == other.message;

  @override
  int get hashCode => message.hashCode;
}
