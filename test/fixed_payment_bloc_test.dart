import 'package:bloc_testmate/bloc_testmate.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payments_bloc.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_event.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_state.dart';
import 'package:gestr/domain/entities/fixed_payments_model.dart';
import 'package:gestr/domain/repositories/fixedpayments/fixed_payments_repository.dart';
import 'package:gestr/domain/usecases/fixed_payments_usecases.dart/fixed_payment_usecases.dart';

class _FakeFixedRepo implements FixedPaymentRepository {
  final List<FixedPayment> list;
  _FakeFixedRepo(this.list);

  @override
  Future<List<FixedPayment>> getFixedPayments(String userId) async => list;
  @override
  Future<void> createFixedPayment(String userId, FixedPayment payment) async {}
  @override
  Future<void> deleteFixedPayment(String userId, String paymentId) async {}
  @override
  Future<FixedPayment?> getFixedPaymentById(String userId, String id) async => null;
  @override
  Future<void> updateFixedPayment(String userId, FixedPayment payment) async {}
}

void main() {
  final mate = BlocTestMate<FixedPaymentBloc, FixedPaymentState>()
      .factory((get) => FixedPaymentBloc(get<FixedPaymentUseCases>(), 'user-1'));

  mate.scenario(
    'fetch fixed payments success',
    arrange: (get) => get.register<FixedPaymentUseCases>(FixedPaymentUseCases(_FakeFixedRepo(const []))),
    when: (bloc) => bloc.add(const FixedPaymentEvent.fetch()),
    expectStates: [isA<FixedPaymentLoading>(), isA<FixedPaymentLoaded>()],
  );
}
