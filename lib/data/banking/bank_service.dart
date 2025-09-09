import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gestr/domain/entities/bank_transaction.dart';

/// Service for retrieving bank transactions from the Tink API.
class BankService {
  final String baseUrl;
  final http.Client _client;

  BankService({this.baseUrl = 'https://api.tink.com', http.Client? client})
    : _client = client ?? http.Client();

  Future<List<BankTransaction>> fetchTransactions(String token) async {
    final uri = Uri.parse('$baseUrl/data/transactions');
    final resp = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to load transactions');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = data['transactions'] as List<dynamic>? ?? [];
    return list
        .map(
          (e) => BankTransaction(
            id: e['id']?.toString(),
            description: e['description'] ?? '',
            date: DateTime.parse(e['date']),
            amount: ((e['amount']?['value'] ?? 0) as num).toDouble() / 100,
          ),
        )
        .toList();
  }
}
