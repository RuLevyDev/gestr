import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/domain/errors/user_profile_failures.dart';
import 'package:gestr/domain/repositories/invoice/invoice_reposiroty.dart';
import 'package:gestr/domain/repositories/user/self_employed_repository.dart';
import 'package:gestr/domain/usecases/sii/sii_usecases.dart';

class _FakeInvoiceRepository implements InvoiceRepository {
  final List<Invoice> _invoices;

  _FakeInvoiceRepository(this._invoices);

  @override
  Future<void> createInvoice(String userId, Invoice invoice) =>
      throw UnimplementedError();

  @override
  Future<void> deleteInvoice(String userId, String invoiceId) =>
      throw UnimplementedError();

  @override
  Future<Invoice?> getInvoiceById(String userId, String id) =>
      throw UnimplementedError();

  @override
  Future<List<Invoice>> getInvoices(String userId) async => _invoices;

  @override
  Future<void> updateInvoice(String userId, Invoice invoice) =>
      throw UnimplementedError();
}

class _FakeSelfEmployedUserRepository implements SelfEmployedUserRepository {
  final SelfEmployedUser _user;

  _FakeSelfEmployedUserRepository(this._user);

  @override
  Future<Either<UserProfileFailure, SelfEmployedUser>> getUser(
    String uid,
  ) async => right(_user);

  @override
  Future<Either<UserProfileFailure, Unit>> saveUser(
    SelfEmployedUser user,
  ) async => right(unit);
}

void main() {
  final issuedInvoice = Invoice(
    id: 'issued-1',
    title: 'Factura cliente Francia',
    date: DateTime(2024, 1, 10),
    netAmount: 100,
    iva: 21,
    status: InvoiceStatus.sent,
    receiver: 'Cliente Francés',
    receiverTaxId: 'FR12345678',
    receiverAddress: '10 Rue de Paris',
    receiverCountryCode: 'FR',
    receiverIdType: 'VAT',
    direction: 'issued',
    taxLines: const [TaxLine(rate: 0.21, base: 100, quota: 21)],
  );

  final receivedInvoice = Invoice(
    id: 'received-1',
    title: 'Factura proveedor Alemania',
    date: DateTime(2024, 2, 5),
    netAmount: 200,
    iva: 42,
    status: InvoiceStatus.paid,
    issuer: 'Proveedor Alemán',
    issuerTaxId: 'DE123456789',
    issuerAddress: 'Berliner Str. 5',
    issuerCountryCode: 'DE',
    issuerIdType: 'VAT',
    direction: 'received',
    taxLines: const [TaxLine(rate: 0.21, base: 200, quota: 42)],
  );

  final user = SelfEmployedUser(
    uid: 'user-1',
    fullName: 'María López',
    dni: '12345678Z',
    activity: 'Consultoría',
    startDate: DateTime(2020, 1, 1),
    address: 'Calle Mayor 1',
    iban: 'ES7921000813610123456789',
    usesElectronicInvoicing: true,
    taxationMethod: 'Estimación directa',
    countryCode: 'ES',
    idType: 'NIF',
  );

  final sii = SiiUseCases(
    _FakeInvoiceRepository([issuedInvoice, receivedInvoice]),
    _FakeSelfEmployedUserRepository(user),
  );

  test('exportIssuedJson incluye país y tipoId reales del receptor', () async {
    final json = await sii.exportIssuedJson('user-1');
    final map = jsonDecode(json) as Map<String, dynamic>;
    expect(map['libro'], equals('Expedidas'));
    final registros = map['registros'] as List<dynamic>;
    expect(registros, hasLength(1));
    final receptor = registros.first['receptor'] as Map<String, dynamic>;
    expect(receptor['pais'], equals('FR'));
    expect(receptor['tipoId'], equals('VAT'));
  });

  test(
    'exportReceivedJson incluye país y tipoId del emisor extranjero',
    () async {
      final json = await sii.exportReceivedJson('user-1');
      final map = jsonDecode(json) as Map<String, dynamic>;
      expect(map['libro'], equals('Recibidas'));
      final registros = map['registros'] as List<dynamic>;
      expect(registros, hasLength(1));
      final emisor = registros.first['emisor'] as Map<String, dynamic>;
      expect(emisor['pais'], equals('DE'));
      expect(emisor['tipoId'], equals('VAT'));
      final receptor = registros.first['receptor'] as Map<String, dynamic>;
      expect(receptor['pais'], equals('ES'));
      expect(receptor['tipoId'], equals('NIF'));
    },
  );
}
