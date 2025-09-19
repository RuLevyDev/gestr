import 'package:cloud_firestore/cloud_firestore.dart';

class SelfEmployedUser {
  final String uid; // Vinculado a FirebaseAuth
  final String fullName;
  final String dni;
  final String activity;
  final DateTime startDate;
  final String address;
  final String iban;
  final bool usesElectronicInvoicing;
  final String taxationMethod;
  final double defaultExpenseVatRate; // 0-0.21
  final bool defaultExpenseAmountIsGross;
  final bool defaultExpenseDeductible;
  final String defaultInvoiceSeries; // para numeración SII (p.ej., "A")
  final String countryCode; // ISO-3166-1 alpha-2 (p.ej., "ES")
  final String idType; // tipo de identificación fiscal (p.ej., "NIF")

  SelfEmployedUser({
    required this.uid,
    required this.fullName,
    required this.dni,
    required this.activity,
    required this.startDate,
    required this.address,
    required this.iban,
    required this.usesElectronicInvoicing,
    required this.taxationMethod,
    this.defaultExpenseVatRate = 0.0,
    this.defaultExpenseAmountIsGross = true,
    this.defaultExpenseDeductible = true,
    this.defaultInvoiceSeries = 'A',
    this.countryCode = 'ES',
    this.idType = 'NIF',
  });

  factory SelfEmployedUser.fromJson(Map<String, dynamic> json) {
    return SelfEmployedUser(
      uid: json['uid'] as String,
      fullName: json['fullName'] as String,
      dni: json['dni'] as String,
      activity: json['activity'] as String,
      startDate: (json['startDate'] as Timestamp).toDate(),
      address: json['address'] as String,
      iban: json['iban'] as String,
      usesElectronicInvoicing: json['usesElectronicInvoicing'] as bool,
      taxationMethod: json['taxationMethod'] as String,
      defaultExpenseVatRate: (json['defaultExpenseVatRate'] ?? 0.0) * 1.0,
      defaultExpenseAmountIsGross:
          (json['defaultExpenseAmountIsGross'] ?? true) as bool,
      defaultExpenseDeductible:
          (json['defaultExpenseDeductible'] ?? true) as bool,
      defaultInvoiceSeries: (json['defaultInvoiceSeries'] as String?) ?? 'A',
      countryCode: (json['countryCode'] as String?) ?? 'ES',
      idType: (json['idType'] as String?) ?? 'NIF',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'dni': dni,
      'activity': activity,
      'startDate': Timestamp.fromDate(startDate),
      'address': address,
      'iban': iban,
      'usesElectronicInvoicing': usesElectronicInvoicing,
      'taxationMethod': taxationMethod,
      'defaultExpenseVatRate': defaultExpenseVatRate,
      'defaultExpenseAmountIsGross': defaultExpenseAmountIsGross,
      'defaultExpenseDeductible': defaultExpenseDeductible,
      'defaultInvoiceSeries': defaultInvoiceSeries,
      'countryCode': countryCode,
      'idType': idType,
    };
  }
}
