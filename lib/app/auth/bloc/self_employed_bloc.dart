import 'package:flutter_bloc/flutter_bloc.dart';

import 'self_employed_event.dart';
import 'self_employed_state.dart';

import '../../../domain/usecases/user/self_employed_user_usecases.dart';

class SelfEmployedBloc extends Bloc<SelfEmployedEvent, SelfEmployedState> {
  final SelfEmployedUserUseCases useCases;

  SelfEmployedBloc(this.useCases) : super(SelfEmployedInitial()) {
    on<SaveSelfEmployedUser>(_onSaveUser);
  }

  Future<void> _onSaveUser(
    SaveSelfEmployedUser event,
    Emitter<SelfEmployedState> emit,
  ) async {
    emit(SelfEmployedLoading());
    final result = await useCases.saveUser(event.user);
    result.fold(
      (failure) => emit(SelfEmployedError(failure.toString())),
      (_) => emit(SelfEmployedSaved()),
    );
  }
}
