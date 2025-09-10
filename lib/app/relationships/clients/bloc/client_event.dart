import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/client.dart';

enum ClientEventType { fetch, refresh, create, delete, getById }

class ClientEvent extends Equatable {
  final ClientEventType type;
  final Client? client;
  final String? id;

  const ClientEvent._(this.type, {this.client, this.id});
  const ClientEvent.fetch() : this._(ClientEventType.fetch);
  const ClientEvent.refresh() : this._(ClientEventType.refresh);
  const ClientEvent.create(Client client)
    : this._(ClientEventType.create, client: client);
  const ClientEvent.delete(String id) : this._(ClientEventType.delete, id: id);
  const ClientEvent.getById(String id)
    : this._(ClientEventType.getById, id: id);

  @override
  List<Object?> get props => [type, client, id];
}
