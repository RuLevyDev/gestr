import 'package:gestr/domain/entities/client.dart';

abstract class ClientRepository {
  Future<List<Client>> getClients(String userId);
  Future<void> createClient(String userId, Client client);
  Future<void> updateClient(String userId, Client client);
  Future<void> deleteClient(String userId, String clientId);
  Future<Client?> getClientById(String userId, String id);
}
