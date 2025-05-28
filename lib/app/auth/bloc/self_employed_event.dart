import 'package:gestr/domain/entities/self_employed_user.dart';

abstract class SelfEmployedEvent {}

class SaveSelfEmployedUser extends SelfEmployedEvent {
  final SelfEmployedUser user;
  SaveSelfEmployedUser(this.user);
}
