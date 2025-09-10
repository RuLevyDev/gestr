import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestr/domain/entities/client.dart';
import 'package:gestr/domain/repositories/client/client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final FirebaseFirestore firestore;
  ClientRepositoryImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      firestore.collection('users').doc(userId).collection('clients');

  @override
  Future<List<Client>> getClients(String userId) async {
    final snap = await _col(userId).orderBy('name').get();
    return snap.docs.map((d) {
      final m = d.data();
      return Client(
        id: d.id,
        name: m['name'] ?? '',
        email: m['email'],
        phone: m['phone'],
        taxId: m['taxId'],
        fiscalAddress: m['fiscalAddress'],
      );
    }).toList();
  }

  @override
  Future<void> createClient(String userId, Client client) async {
    await _col(userId).add({
      'name': client.name,
      'email': client.email,
      'phone': client.phone,
      'taxId': client.taxId,
      'fiscalAddress': client.fiscalAddress,
    });
  }

  @override
  Future<void> updateClient(String userId, Client client) async {
    if (client.id == null) return;
    await _col(userId).doc(client.id).update({
      'name': client.name,
      'email': client.email,
      'phone': client.phone,
      'taxId': client.taxId,
      'fiscalAddress': client.fiscalAddress,
    });
  }

  @override
  Future<void> deleteClient(String userId, String clientId) async {
    await _col(userId).doc(clientId).delete();
  }

  @override
  Future<Client?> getClientById(String userId, String id) async {
    final doc = await _col(userId).doc(id).get();
    if (!doc.exists) return null;
    final m = doc.data()!;
    return Client(
      id: doc.id,
      name: m['name'] ?? '',
      email: m['email'],
      phone: m['phone'],
      taxId: m['taxId'],
      fiscalAddress: m['fiscalAddress'],
    );
  }
}
