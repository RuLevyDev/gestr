abstract class SelfEmployedState {}

class SelfEmployedInitial extends SelfEmployedState {}

class SelfEmployedLoading extends SelfEmployedState {}

class SelfEmployedSaved extends SelfEmployedState {}

class SelfEmployedError extends SelfEmployedState {
  final String message;
  SelfEmployedError(this.message);
}
