import 'package:gestr/domain/entities/client.dart';
import 'package:gestr/domain/repositories/client/client_repository.dart';

class ClientUseCases {
  final ClientRepository _repo;
  ClientUseCases(this._repo);

  Future<List<Client>> fetch(String userId) => _repo.getClients(userId);
  Future<void> create(String userId, Client client) =>
      _repo.createClient(userId, client);
  Future<void> update(String userId, Client client) =>
      _repo.updateClient(userId, client);
  Future<void> delete(String userId, String id) =>
      _repo.deleteClient(userId, id);
  Future<Client?> getById(String userId, String id) =>
      _repo.getClientById(userId, id);
}
