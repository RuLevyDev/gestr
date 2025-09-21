import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestr/domain/entities/income.dart';
import 'package:gestr/domain/repositories/income/income_repository.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  final FirebaseFirestore firestore;
  IncomeRepositoryImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      firestore.collection('users').doc(userId).collection('incomes');

  @override
  Future<List<Income>> getIncomes(String userId) async {
    final snap = await _col(userId).orderBy('date', descending: true).get();

    final items = <Income>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['voidedAt'] != null) {
        continue;
      }
      items.add(_mapIncome(doc.id, data));
    }
    return items;
  }

  @override
  Future<void> createIncome(String userId, Income income) async {
    await _col(userId).add({
      'title': income.title,
      'date': income.date,
      'amount': income.amount,
      'source': income.source,
      'voidedAt': null,
      'voidedBy': null,
      'voidReason': null,
    });
  }

  @override
  Future<Income> voidIncome(
    String userId,
    String incomeId, {
    String? voidedBy,
    String? voidReason,
  }) async {
    final docRef = _col(userId).doc(incomeId);
    await docRef.update({
      'voidedAt': FieldValue.serverTimestamp(),
      'voidedBy': voidedBy ?? userId,
      'voidReason': voidReason,
    });
    final updated = await docRef.get();
    if (!updated.exists) {
      throw Exception('Ingreso no encontrado');
    }
    return _mapIncome(updated.id, updated.data()!);
  }

  @override
  Future<Income?> getIncomeById(String userId, String id) async {
    final doc = await _col(userId).doc(id).get();
    if (!doc.exists) return null;
    final m = doc.data()!;

    return _mapIncome(doc.id, m);
  }

  @override
  Future<void> updateIncome(String userId, Income income) async {
    if (income.id == null) return;
    await _col(userId).doc(income.id).update({
      'title': income.title,
      'date': income.date,
      'amount': income.amount,
      'source': income.source,
      'voidedAt': income.voidedAt,
      'voidedBy': income.voidedBy,
      'voidReason': income.voidReason,
    });
  }

  Income _mapIncome(String id, Map<String, dynamic> data) {
    final voidedAtRaw = data['voidedAt'];
    DateTime? voidedAt;
    if (voidedAtRaw is Timestamp) {
      voidedAt = voidedAtRaw.toDate();
    } else if (voidedAtRaw is DateTime) {
      voidedAt = voidedAtRaw;
    } else if (voidedAtRaw is String) {
      voidedAt = DateTime.tryParse(voidedAtRaw);
    }
    return Income(
      id: id,
      title: data['title'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      source: data['source'] as String?,
      voidedAt: voidedAt,
      voidedBy: data['voidedBy'] as String?,
      voidReason: data['voidReason'] as String?,
    );
  }
}
