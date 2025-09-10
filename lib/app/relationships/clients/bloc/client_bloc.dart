import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/domain/entities/client.dart';
import 'package:gestr/domain/usecases/client/client_usecases.dart';

import 'client_event.dart';
import 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final ClientUseCases useCases;
  final String userId;
  ClientBloc(this.useCases, this.userId) : super(ClientInitial()) {
    on<ClientEvent>(_onEvent);
  }

  Future<void> _onEvent(ClientEvent event, Emitter<ClientState> emit) async {
    switch (event.type) {
      case ClientEventType.fetch:
        await _fetch(emit);
        break;
      case ClientEventType.refresh:
        await _refresh(emit);
        break;
      case ClientEventType.create:
        await _create(event.client!, emit);
        break;
      case ClientEventType.delete:
        await _delete(event.id!, emit);
        break;
      case ClientEventType.getById:
        await _getById(event.id!, emit);
        break;
    }
  }

  Future<void> _fetch(Emitter<ClientState> emit) async {
    emit(ClientLoading());
    try {
      final list = await useCases.fetch(userId);
      emit(ClientLoaded(list));
    } catch (_) {
      emit(const ClientError('No se pudieron cargar los clientes.'));
    }
  }

  Future<void> _refresh(Emitter<ClientState> emit) async {
    try {
      final list = await useCases.fetch(userId);
      emit(ClientLoaded(list));
    } catch (_) {
      emit(const ClientError('Error al refrescar los clientes.'));
    }
  }

  Future<void> _create(Client client, Emitter<ClientState> emit) async {
    try {
      await useCases.create(userId, client);
      final list = await useCases.fetch(userId);
      emit(ClientLoaded(list));
    } catch (_) {
      emit(const ClientError('No se pudo crear el cliente.'));
    }
  }

  Future<void> _delete(String id, Emitter<ClientState> emit) async {
    try {
      await useCases.delete(userId, id);
      final list = await useCases.fetch(userId);
      emit(ClientLoaded(list));
    } catch (_) {
      emit(const ClientError('No se pudo eliminar el cliente.'));
    }
  }

  Future<void> _getById(String id, Emitter<ClientState> emit) async {
    emit(ClientLoading());
    try {
      final item = await useCases.getById(userId, id);
      if (item == null) {
        emit(const ClientError('Cliente no encontrado.'));
      } else {
        emit(ClientLoaded([item]));
      }
    } catch (_) {
      emit(const ClientError('No se pudo cargar el cliente.'));
    }
  }
}
