import 'package:flutter/material.dart';

class AdvancedCounterpartyFields extends StatelessWidget {
  const AdvancedCounterpartyFields({
    super.key,
    required this.isIssued,
    required this.theme,
    required this.invoiceNumberController,
    required this.onInvoiceNumberChanged,
    this.onInvoiceNumberSaved,
    required this.receiverTaxIdController,
    required this.receiverAddressController,
    required this.issuerTaxIdController,
    required this.issuerAddressController,
    required this.onReceiverTaxIdChanged,
    required this.onReceiverAddressChanged,
    required this.onIssuerTaxIdChanged,
    required this.onIssuerAddressChanged,
  });

  final bool isIssued;
  final ThemeData theme;
  final TextEditingController invoiceNumberController;
  final ValueChanged<String> onInvoiceNumberChanged;
  final FormFieldSetter<String>? onInvoiceNumberSaved;
  final TextEditingController receiverTaxIdController;
  final TextEditingController receiverAddressController;
  final TextEditingController issuerTaxIdController;
  final TextEditingController issuerAddressController;
  final ValueChanged<String> onReceiverTaxIdChanged;
  final ValueChanged<String> onReceiverAddressChanged;
  final ValueChanged<String> onIssuerTaxIdChanged;
  final ValueChanged<String> onIssuerAddressChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: invoiceNumberController,
          decoration: InputDecoration(
            labelText: 'Numero de factura',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.onSurface),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          onChanged: onInvoiceNumberChanged,
          onSaved: onInvoiceNumberSaved,
        ),
        const SizedBox(height: 12),
        if (isIssued) ...[
          TextFormField(
            controller: receiverTaxIdController,
            decoration: InputDecoration(
              labelText: 'NIF receptor',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.onSurface),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            onChanged: onReceiverTaxIdChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: receiverAddressController,
            decoration: InputDecoration(
              labelText: 'Direccion receptor',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.onSurface),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            maxLines: 2,
            onChanged: onReceiverAddressChanged,
          ),
        ] else ...[
          TextFormField(
            controller: issuerTaxIdController,
            decoration: InputDecoration(
              labelText: 'NIF emisor',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.onSurface),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            onChanged: onIssuerTaxIdChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: issuerAddressController,
            decoration: InputDecoration(
              labelText: 'Direccion emisor',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.onSurface),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            maxLines: 2,
            onChanged: onIssuerAddressChanged,
          ),
        ],
      ],
    );
  }
}
