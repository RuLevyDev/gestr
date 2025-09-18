import 'dart:ui';
import 'package:flutter/material.dart';

class AmountSection extends StatelessWidget {
  const AmountSection({
    super.key,
    required this.amountController,
    required this.ivaController,
    required this.amount,
    required this.iva,
    required this.vatRate,
    required this.includeIva,
    required this.onAmountChanged,
    required this.onIncludeIvaChanged,
    required this.onVatRateChanged,
    required this.onIvaChanged,
  });

  final TextEditingController amountController;
  final TextEditingController ivaController;
  final double amount;
  final double iva;
  final double vatRate;
  final bool includeIva;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<bool> onIncludeIvaChanged;
  final ValueChanged<double> onVatRateChanged;
  final ValueChanged<String> onIvaChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.tealAccent.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Base imponible',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.onSurface),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onChanged: onAmountChanged,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Importe incluye IVA'),
                        value: includeIva,
                        onChanged: onIncludeIvaChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: includeIva ? 1.0 : 0.5,
                    child: DropdownButton<double>(
                      value: vatRate,
                      items: const [0.0, 4.0, 10.0, 21.0]
                          .map(
                            (r) => DropdownMenuItem<double>(
                              value: r,
                              child: Text('${r.toStringAsFixed(0)}%'),
                            ),
                          )
                          .toList(),
                      onChanged: includeIva
                          ? (r) {
                              if (r == null) return;
                              onVatRateChanged(r);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!includeIva)
                TextFormField(
                  controller: ivaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'IVA',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: theme.colorScheme.onSurface),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: onIvaChanged,
                ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final total = (amount + iva).toStringAsFixed(2);
                  if (includeIva) {
                    final base = amount.toStringAsFixed(2);
                    final cuota = iva.toStringAsFixed(2);
                    return Text(
                      'Total: $total EUR  (Base: $base, IVA: $cuota @ ${vatRate.toStringAsFixed(0)}%)',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    );
                  }
                  return Text(
                    'Total: $total EUR',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

