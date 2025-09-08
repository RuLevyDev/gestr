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
      defaultExpenseAmountIsGross: (json['defaultExpenseAmountIsGross'] ?? true) as bool,
      defaultExpenseDeductible: (json['defaultExpenseDeductible'] ?? true) as bool,
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
    };
  }
}
