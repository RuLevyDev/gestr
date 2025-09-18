import 'package:flutter/material.dart';
import 'package:gestr/app/invoices/application/view/widgets/counterparty_field.dart';
import 'package:gestr/app/invoices/application/view/widgets/advanced_counterparty_fields.dart';

class CounterpartySection extends StatelessWidget {
  const CounterpartySection({
    super.key,
    required this.isIssued,
    required this.theme,
    required this.label,
    required this.nameController,
    required this.receiverTaxIdController,
    required this.receiverAddressController,
    required this.issuerTaxIdController,
    required this.issuerAddressController,
    required this.showAdvancedFields,
    required this.suggestions,
    required this.onChanged,
    required this.onSubmitted,
    required this.onTapSuggestion,
    required this.invoiceNumberController,
    required this.onInvoiceNumberChanged,
    required this.onInvoiceNumberSaved,
    required this.onReceiverTaxIdChanged,
    required this.onReceiverAddressChanged,
    required this.onIssuerTaxIdChanged,
    required this.onIssuerAddressChanged,
  });

  final bool isIssued;
  final ThemeData theme;
  final String label;
  final TextEditingController nameController;
  final TextEditingController receiverTaxIdController;
  final TextEditingController receiverAddressController;
  final TextEditingController issuerTaxIdController;
  final TextEditingController issuerAddressController;
  final bool showAdvancedFields;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final void Function(int index) onTapSuggestion;
  final TextEditingController invoiceNumberController;
  final ValueChanged<String> onInvoiceNumberChanged;
  final FormFieldSetter<String>? onInvoiceNumberSaved;
  final ValueChanged<String> onReceiverTaxIdChanged;
  final ValueChanged<String> onReceiverAddressChanged;
  final ValueChanged<String> onIssuerTaxIdChanged;
  final ValueChanged<String> onIssuerAddressChanged;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      CounterpartyField(
        label: label,
        controller: nameController,
        theme: theme,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        suggestions: suggestions,
        onTapSuggestion: onTapSuggestion,
      ),
    ];

    final summaryTax =
        isIssued ? receiverTaxIdController : issuerTaxIdController;
    final summaryAddr =
        isIssued ? receiverAddressController : issuerAddressController;
    final hasSummary =
        summaryTax.text.trim().isNotEmpty || summaryAddr.text.trim().isNotEmpty;
    if (!showAdvancedFields && hasSummary) {
      children.add(const SizedBox(height: 8));
      if (summaryTax.text.trim().isNotEmpty) {
        children.add(
          Text('NIF: ${summaryTax.text}', style: const TextStyle(fontSize: 12)),
        );
      }
      if (summaryAddr.text.trim().isNotEmpty) {
        children.add(
          Text(summaryAddr.text, style: const TextStyle(fontSize: 12)),
        );
      }
    }

    if (showAdvancedFields) {
      children.add(
        AdvancedCounterpartyFields(
          isIssued: isIssued,
          theme: theme,
          invoiceNumberController: invoiceNumberController,
          onInvoiceNumberChanged: onInvoiceNumberChanged,
          onInvoiceNumberSaved: onInvoiceNumberSaved,
          receiverTaxIdController: receiverTaxIdController,
          receiverAddressController: receiverAddressController,
          issuerTaxIdController: issuerTaxIdController,
          issuerAddressController: issuerAddressController,
          onReceiverTaxIdChanged: onReceiverTaxIdChanged,
          onReceiverAddressChanged: onReceiverAddressChanged,
          onIssuerTaxIdChanged: onIssuerTaxIdChanged,
          onIssuerAddressChanged: onIssuerAddressChanged,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
