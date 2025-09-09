import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/domain/usecases/banking/bank_usecases.dart';

import 'bank_transaction_event.dart';
import 'bank_transaction_state.dart';

class BankTransactionBloc
    extends Bloc<BankTransactionEvent, BankTransactionState> {
  final BankUseCases useCases;
  final String userId;

  BankTransactionBloc(this.useCases, this.userId)
    : super(BankTransactionInitial()) {
    on<BankTransactionEvent>(_onEvent);
  }

  Future<void> _onEvent(
    BankTransactionEvent event,
    Emitter<BankTransactionState> emit,
  ) async {
    switch (event.type) {
      case BankTransactionEventType.fetch:
        await _fetch(emit);
        break;
      case BankTransactionEventType.link:
        await _link(event.transactionId!, event.incomeId!, emit);
        break;
    }
  }

  Future<void> _fetch(Emitter<BankTransactionState> emit) async {
    emit(BankTransactionLoading());
    try {
      final list = await useCases.fetch(userId);
      emit(BankTransactionLoaded(list));
    } catch (_) {
      emit(
        const BankTransactionError('No se pudieron cargar las transacciones.'),
      );
    }
  }

  Future<void> _link(
    String txId,
    String incomeId,
    Emitter<BankTransactionState> emit,
  ) async {
    try {
      await useCases.link(userId, txId, incomeId);
      final list = await useCases.fetch(userId);
      emit(BankTransactionLoaded(list));
    } catch (_) {
      emit(const BankTransactionError('No se pudo vincular la transacción.'));
    }
  }
}
