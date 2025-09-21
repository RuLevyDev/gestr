import 'package:gestr/domain/entities/supplier_order_item.dart';
import 'package:gestr/domain/entities/supplier_order.dart';

class Supplier {
  final String? id;
  final String name;
  final String? email;
  final String? phone;
  final String? taxId;
  final String? fiscalAddress;
  final String? countryCode; // ISO-3166-1 alpha-2 (e.g., ES)
  final String? idType; // e.g., NIF, NIE, VAT, OTHER
  final List<SupplierOrderItem> orderItems;
  final List<SupplierOrder> orders;
  final DateTime? voidedAt;
  final String? voidedBy;
  final String? voidReason;

  const Supplier({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.taxId,
    this.fiscalAddress,
    this.countryCode,
    this.idType,
    this.orderItems = const [],
    this.orders = const [],
    this.voidedAt,
    this.voidedBy,
    this.voidReason,
  });
}
