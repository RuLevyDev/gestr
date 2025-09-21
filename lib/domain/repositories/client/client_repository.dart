import 'package:gestr/domain/entities/client.dart';

abstract class ClientRepository {
  Future<List<Client>> getClients(String userId);
  Future<void> createClient(String userId, Client client);
  Future<void> updateClient(String userId, Client client);
  Future<Client> voidClient(
    String userId,
    String clientId, {
    String? voidedBy,
    String? voidReason,
  });
  Future<Client?> getClientById(String userId, String id);
}
