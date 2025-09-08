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
    return snap.docs.map((d) {
      final m = d.data();
      return Income(
        id: d.id,
        title: m['title'] ?? '',
        date: (m['date'] as Timestamp).toDate(),
        amount: (m['amount'] ?? 0).toDouble(),
        source: m['source'],
      );
    }).toList();
  }

  @override
  Future<void> createIncome(String userId, Income income) async {
    await _col(userId).add({
      'title': income.title,
      'date': income.date,
      'amount': income.amount,
      'source': income.source,
    });
  }

  @override
  Future<void> deleteIncome(String userId, String incomeId) async {
    await _col(userId).doc(incomeId).delete();
  }

  @override
  Future<Income?> getIncomeById(String userId, String id) async {
    final doc = await _col(userId).doc(id).get();
    if (!doc.exists) return null;
    final m = doc.data()!;
    return Income(
      id: doc.id,
      title: m['title'] ?? '',
      date: (m['date'] as Timestamp).toDate(),
      amount: (m['amount'] ?? 0).toDouble(),
      source: m['source'],
    );
  }

  @override
  Future<void> updateIncome(String userId, Income income) async {
    if (income.id == null) return;
    await _col(userId).doc(income.id).update({
      'title': income.title,
      'date': income.date,
      'amount': income.amount,
      'source': income.source,
    });
  }
}

