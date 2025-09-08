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
  final String? supplier;
  final double vatRate; // 0, 0.04, 0.10, 0.21
  final bool amountIsGross; // true: amount = base+IVA; false: amount = base
  final bool deductible; // si puede deducirse el IVA
  final FixedPaymentCategory category;
  final File? image;
  final String? imageUrl;

  FixedPayment({
    this.id,
    required this.title,
    required this.amount,
    required this.startDate,
    required this.frequency,
    this.description,
    this.supplier,
    this.vatRate = 0.0,
    this.amountIsGross = true,
    this.deductible = true,
    this.category = FixedPaymentCategory.other,
    this.image,
    this.imageUrl,
  });
}

enum FixedPaymentCategory {
  utilities,
  rent,
  vehicle,
  food,
  tools,
  services,
  taxes,
  other,
}

extension FixedPaymentCategoryName on FixedPaymentCategory {
  String get nameEs {
    switch (this) {
      case FixedPaymentCategory.utilities:
        return 'Suministros';
      case FixedPaymentCategory.rent:
        return 'Alquiler';
      case FixedPaymentCategory.vehicle:
        return 'Vehículo';
      case FixedPaymentCategory.food:
        return 'Dietas';
      case FixedPaymentCategory.tools:
        return 'Herramientas';
      case FixedPaymentCategory.services:
        return 'Servicios';
      case FixedPaymentCategory.taxes:
        return 'Impuestos';
      case FixedPaymentCategory.other:
        return 'Otros';
    }
  }
}
