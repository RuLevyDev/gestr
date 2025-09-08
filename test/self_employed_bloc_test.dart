import 'package:bloc_testmate/bloc_testmate.dart';
import 'package:dartz/dartz.dart';
import 'package:gestr/app/auth/bloc/self_employed_bloc.dart';
import 'package:gestr/app/auth/bloc/self_employed_event.dart';
import 'package:gestr/app/auth/bloc/self_employed_state.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/domain/errors/user_profile_failures.dart';
import 'package:gestr/domain/repositories/user/self_employed_repository.dart';
import 'package:gestr/domain/usecases/user/self_employed_user_usecases.dart';

class _FakeSelfRepo implements SelfEmployedUserRepository {
  final bool ok;
  _FakeSelfRepo(this.ok);
  @override
  Future<Either<UserProfileFailure, SelfEmployedUser>> getUser(String uid) async => Left(UserNotFound());
  @override
  Future<Either<UserProfileFailure, Unit>> saveUser(SelfEmployedUser user) async =>
      ok ? const Right(unit) : Left(UnknownUserProfileFailure('fail'));
}

void main() {
  final mate = BlocTestMate<SelfEmployedBloc, SelfEmployedState>()
      .factory((get) => SelfEmployedBloc(get<SelfEmployedUserUseCases>()));

  final sample = SelfEmployedUser(
    uid: 'u',
    fullName: 'Nombre',
    dni: '12345678Z',
    activity: 'Dev',
    startDate: DateTime(2020, 1, 1),
    address: 'Dir',
    iban: 'ES11223344556677889900',
    usesElectronicInvoicing: false,
    taxationMethod: 'Estimación directa',
  );

  mate.scenario(
    'save success',
    arrange: (get) => get.register<SelfEmployedUserUseCases>(SelfEmployedUserUseCases(_FakeSelfRepo(true))),
    when: (bloc) => bloc.add(SaveSelfEmployedUser(sample)),
    expectStates: [isA<SelfEmployedLoading>(), isA<SelfEmployedSaved>()],
  );

  mate.scenario(
    'save error',
    arrange: (get) => get.register<SelfEmployedUserUseCases>(SelfEmployedUserUseCases(_FakeSelfRepo(false))),
    when: (bloc) => bloc.add(SaveSelfEmployedUser(sample)),
    expectStates: [isA<SelfEmployedLoading>(), isA<SelfEmployedError>()],
  );
}
