import 'dart:convert';

import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/domain/repositories/invoice/invoice_reposiroty.dart';
import 'package:gestr/domain/repositories/user/self_employed_repository.dart';
import 'package:gestr/core/sii/sii_mapper.dart';

class SiiUseCases {
  final InvoiceRepository _invoices;
  final SelfEmployedUserRepository _users;
  SiiUseCases(this._invoices, this._users);

  /// Genera el libro de facturas expedidas (emitidas) en JSON listo para enviar/procesar.
  Future<String> exportIssuedJson(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final me = await _getUser(userId);
    final list = await _getInvoices(userId, start: start, end: end);
    final issued = list.where((i) => (i.direction ?? 'issued') == 'issued');
    final mapped = issued.map((i) => SiiMapper.mapIssued(i, me)).toList();
    return jsonEncode({'libro': 'Expedidas', 'registros': mapped});
  }

  /// Genera el libro de facturas recibidas en JSON.
  Future<String> exportReceivedJson(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final me = await _getUser(userId);
    final list = await _getInvoices(userId, start: start, end: end);
    final received = list.where((i) => (i.direction ?? 'issued') == 'received');
    final mapped = received.map((i) => SiiMapper.mapReceived(i, me)).toList();
    return jsonEncode({'libro': 'Recibidas', 'registros': mapped});
  }

  Future<SelfEmployedUser> _getUser(String userId) async {
    final res = await _users.getUser(userId);
    return res.fold((l) => throw Exception('Perfil no disponible'), (r) => r);
  }

  Future<List<Invoice>> _getInvoices(
    String userId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final list = await _invoices.getInvoices(userId);
    bool inRange(DateTime d) {
      final sOk = start == null || !d.isBefore(start);
      final eOk = end == null || !d.isAfter(end);
      return sOk && eOk;
    }

    return (start == null && end == null)
        ? list
        : list.where((i) => inRange(i.date)).toList();
  }
}
