class SupplierOrderItem {
  final String product;
  final double price;
  final int quantity;

  SupplierOrderItem({
    required this.product,
    required this.price,
    this.quantity = 1,
  });

  factory SupplierOrderItem.fromMap(Map<String, dynamic> map) {
    return SupplierOrderItem(
      product: map['product'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] is num ? (map['quantity'] as num).toInt() : 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {'product': product, 'price': price, 'quantity': quantity};
  }
}
