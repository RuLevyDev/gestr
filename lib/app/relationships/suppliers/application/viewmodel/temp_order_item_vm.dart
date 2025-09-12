import 'package:flutter/material.dart';
import 'package:gestr/app/relationships/suppliers/application/widgets/order_items_editor.dart';

class TempOrderItemVm implements OrderItemVm {
  @override
  final TextEditingController productController;
  @override
  final TextEditingController quantityController;
  @override
  final TextEditingController priceController;
  @override
  final bool persisted = false;

  TempOrderItemVm({String product = '', int quantity = 1, double price = 0.0})
    : productController = TextEditingController(text: product),
      quantityController = TextEditingController(text: quantity.toString()),
      priceController = TextEditingController(
        text: price == 0.0 ? '' : price.toString(),
      );

  void dispose() {
    productController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}
