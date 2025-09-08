import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/tax_client_total.dart';

abstract class TopClientsState extends Equatable {
  const TopClientsState();
  @override
  List<Object?> get props => [];
}

class TopClientsInitial extends TopClientsState {}

class TopClientsLoading extends TopClientsState {}

class TopClientsLoaded extends TopClientsState {
  final List<ClientTotal> clients;
  const TopClientsLoaded(this.clients);
  @override
  List<Object?> get props => [clients];
}

class TopClientsError extends TopClientsState {
  final String message;
  const TopClientsError(this.message);
  @override
  List<Object?> get props => [message];
}
