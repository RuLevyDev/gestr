import 'package:gestr/domain/entities/supplier_order_item.dart';

class SupplierOrder {
  final DateTime date;
  final List<SupplierOrderItem> items;
  final String? title;

  const SupplierOrder({required this.date, this.items = const [], this.title});

  factory SupplierOrder.fromMap(Map<String, dynamic> map) {
    return SupplierOrder(
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      items: (map['items'] as List<dynamic>? ?? [])
          .map(
            (e) => SupplierOrderItem.fromMap(
              Map<String, dynamic>.from(e as Map<String, dynamic>),
            ),
          )
          .toList(),
      title: map['title'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toMap()).toList(),
      'title': title,
    };
  }
}
