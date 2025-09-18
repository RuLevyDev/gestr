import 'package:flutter/material.dart';
import 'concept_section.dart';

typedef ItemTuple = MapEntry<double, double>; // qty, price

class ItemsAmountBinder extends StatefulWidget {
  const ItemsAmountBinder({
    super.key,
    required this.itemsMode,
    required this.toggleItemsMode,
    required this.conceptController,
    this.initialItemCount = 1,
    required this.onTuplesChanged,
    this.onConceptTextChanged,
  });

  final bool itemsMode;
  final VoidCallback toggleItemsMode;
  final TextEditingController conceptController;
  final int initialItemCount;
  final void Function(List<ItemTuple> tuples) onTuplesChanged;
  final void Function(String? conceptText)? onConceptTextChanged;

  @override
  State<ItemsAmountBinder> createState() => _ItemsAmountBinderState();
}

class _ItemsAmountBinderState extends State<ItemsAmountBinder> {
  late final List<ConceptItemRowData> _items;

  @override
  void initState() {
    super.initState();
    _items = List.generate(
      widget.initialItemCount,
      (_) => ConceptItemRowData(),
    );
  }

  @override
  void dispose() {
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final tuples = <ItemTuple>[];
    final lines = <String>[];
    for (final it in _items) {
      final name = it.productCtrl.text.trim();
      final q = double.tryParse(it.qtyCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final p = double.tryParse(it.priceCtrl.text.replaceAll(',', '.')) ?? 0.0;
      tuples.add(ItemTuple(q, p));
      if (name.isNotEmpty) {
        final imp = q * p;
        lines.add(
          '$name x ${q.toStringAsFixed(2)} @ ${p.toStringAsFixed(2)} = ${imp.toStringAsFixed(2)}',
        );
      }
    }
    widget.onTuplesChanged(tuples);
    widget.onConceptTextChanged?.call(lines.isEmpty ? null : lines.join('\n'));
  }

  void _addLine() {
    setState(() => _items.add(ConceptItemRowData()));
    _emit();
  }

  void _removeLine(int i) {
    if (i < 0 || i >= _items.length) return;
    final row = _items.removeAt(i);
    row.dispose();
    setState(() {});
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return ConceptSection(
      itemsMode: widget.itemsMode,
      toggleItemsMode: () {
        widget.toggleItemsMode();
        _emit();
      },
      conceptController: widget.conceptController,
      items: _items,
      onAddLine: _addLine,
      onRemoveLine: _removeLine,
      onItemsChanged: _emit,
    );
  }
}
