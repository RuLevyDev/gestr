import 'package:gestr/domain/entities/fixed_payments_model.dart';

class CategoryTotal {
  final FixedPaymentCategory category;
  final double total;

  const CategoryTotal(this.category, this.total);
}
