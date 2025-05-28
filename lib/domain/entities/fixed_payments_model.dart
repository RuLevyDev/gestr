import 'dart:io';

enum FixedPaymentFrequency {
  weekly,
  monthly,
  quarterly, // nuevo
  fourMonthly, // nuevo
  semiYearly, // nuevo
  yearly,
  custom,
}

extension FixedPaymentFrequencyExtension on FixedPaymentFrequency {
  String get name {
    switch (this) {
      case FixedPaymentFrequency.weekly:
        return 'weekly';
      case FixedPaymentFrequency.monthly:
        return 'monthly';
      case FixedPaymentFrequency.quarterly:
        return 'quarterly';
      case FixedPaymentFrequency.fourMonthly:
        return 'fourmonthly';
      case FixedPaymentFrequency.semiYearly:
        return 'semiyearly';
      case FixedPaymentFrequency.yearly:
        return 'yearly';
      case FixedPaymentFrequency.custom:
        return 'custom';
    }
  }
}

extension FixedPaymentFrequencyTraduccion on FixedPaymentFrequency {
  String get labelEs {
    switch (this) {
      case FixedPaymentFrequency.weekly:
        return 'Semanal';
      case FixedPaymentFrequency.monthly:
        return 'Mensual';
      case FixedPaymentFrequency.quarterly:
        return 'Trimestral';
      case FixedPaymentFrequency.fourMonthly:
        return 'Cuatrimestral';
      case FixedPaymentFrequency.semiYearly:
        return 'Semestral';
      case FixedPaymentFrequency.yearly:
        return 'Anual';
      case FixedPaymentFrequency.custom:
        return 'Personalizada';
    }
  }
}

class FixedPayment {
  final String? id;
  final String title;
  final double amount;
  final DateTime startDate;
  final FixedPaymentFrequency frequency;
  final String? description;
  final File? image;
  final String? imageUrl;

  FixedPayment({
    this.id,
    required this.title,
    required this.amount,
    required this.startDate,
    required this.frequency,
    this.description,
    this.image,
    this.imageUrl,
  });
}
