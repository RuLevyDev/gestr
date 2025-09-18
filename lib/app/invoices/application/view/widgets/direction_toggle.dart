import 'package:flutter/material.dart';
import 'package:gestr/app/invoices/application/viewmodel/create_invoice_viewmodel.dart';

class DirectionToggle extends StatelessWidget {
  const DirectionToggle({
    super.key,
    required this.direction,
    required this.onChanged,
  });

  final InvoiceDirection direction;
  final ValueChanged<InvoiceDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<InvoiceDirection>(
        segments: const <ButtonSegment<InvoiceDirection>>[
          ButtonSegment(value: InvoiceDirection.issued, label: Text('Emitida')),
          ButtonSegment(
            value: InvoiceDirection.received,
            label: Text('Recibida'),
          ),
        ],
        selected: <InvoiceDirection>{direction},
        onSelectionChanged: (selection) => onChanged(selection.first),
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

