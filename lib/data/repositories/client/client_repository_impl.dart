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

    final clients = <Client>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['voidedAt'] != null) {
        continue;
      }
      clients.add(_mapClient(doc.id, data));
    }
    return clients;
  }

  @override
  Future<void> createClient(String userId, Client client) async {
    await _col(userId).add({
      'name': client.name,
      'email': client.email,
      'phone': client.phone,
      'taxId': client.taxId,
      'fiscalAddress': client.fiscalAddress,
      'countryCode': client.countryCode,
      'idType': client.idType,
      'voidedAt': null,
      'voidedBy': null,
      'voidReason': null,
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
      'countryCode': client.countryCode,
      'idType': client.idType,
      'voidedAt': client.voidedAt,
      'voidedBy': client.voidedBy,
      'voidReason': client.voidReason,
    });
  }

  @override
  Future<Client> voidClient(
    String userId,
    String clientId, {
    String? voidedBy,
    String? voidReason,
  }) async {
    final docRef = _col(userId).doc(clientId);
    await docRef.update({
      'voidedAt': FieldValue.serverTimestamp(),
      'voidedBy': voidedBy ?? userId,
      'voidReason': voidReason,
    });
    final updated = await docRef.get();
    if (!updated.exists) {
      throw Exception('Cliente no encontrado');
    }
    return _mapClient(updated.id, updated.data()!);
  }

  @override
  Future<Client?> getClientById(String userId, String id) async {
    final doc = await _col(userId).doc(id).get();
    if (!doc.exists) return null;
    final m = doc.data()!;
    return _mapClient(doc.id, m);
  }

  Client _mapClient(String id, Map<String, dynamic> data) {
    final voidedAtRaw = data['voidedAt'];
    DateTime? voidedAt;
    if (voidedAtRaw is Timestamp) {
      voidedAt = voidedAtRaw.toDate();
    } else if (voidedAtRaw is DateTime) {
      voidedAt = voidedAtRaw;
    } else if (voidedAtRaw is String) {
      voidedAt = DateTime.tryParse(voidedAtRaw);
    }
    return Client(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      taxId: data['taxId'] as String?,
      fiscalAddress: data['fiscalAddress'] as String?,
      countryCode: data['countryCode'] as String?,
      idType: data['idType'] as String?,
      voidedAt: voidedAt,
      voidedBy: data['voidedBy'] as String?,
      voidReason: data['voidReason'] as String?,
    );
  }
}
