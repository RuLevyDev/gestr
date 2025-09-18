import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gestr/app/invoices/application/viewmodel/create_invoice_viewmodel.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
// Use cases and providers are now initialized in the mixin

import 'package:gestr/app/invoices/application/view/widgets/concept_section.dart';
import 'package:gestr/app/invoices/application/view/widgets/amount_section.dart';
import 'package:gestr/app/invoices/application/view/widgets/direction_toggle.dart';
// counterparty field and advanced fields are composed by CounterpartySection
import 'package:gestr/app/invoices/application/view/widgets/self_summary.dart';
import 'package:gestr/app/invoices/application/view/widgets/counterparty_section.dart';
import 'package:gestr/app/invoices/application/view/widgets/items_amount_binder.dart';

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage>
    with CreateInvoiceViewModelMixin {
  bool _showSelfSummaryCard = false;
  bool _itemsMode = false;
  void toggleItemsMode() => setState(() => _itemsMode = !_itemsMode);
  void addItemRow() {}
  void removeItemRow(ConceptItemRowData row) {}

  // Items → importes: desacoplado al widget ItemsAmountBinder

  @override
  void initState() {
    super.initState();
    initPartnersFromContext();
  }

  // Datos de clientes/proveedores se cargan desde el mixin

  // No resources to dispose here; children widgets handle their own state

  // Direction toggle moved to widgets/direction_toggle.dart

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: isDark ? const DialogBackground() : const BackgroundLight(),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('Crear Factura', style: theme.textTheme.headlineSmall),
            backgroundColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Container cristal translucido morado para titulo hasta separador
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.tealAccent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mostrar fecha encima del tAtulo a la derecha
                            Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: DirectionToggle(
                                      direction: direction,
                                      onChanged: setDirection,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Fecha:  ${DateFormat('yyyy-MM-dd').format(invoiceDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            // Campo tAtulo
                            TextFormField(
                              key: ValueKey(amount),
                              decoration: InputDecoration(
                                labelText: 'Titulo',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),

                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Requerido'
                                          : null,
                              onSaved: (value) => title = value,
                            ),
                            // Switch para mostrar datos avanzados justo debajo del tAtulo
                            SwitchListTile(
                              title: const Text(
                                'Mostrar datos avanzados (emisor, receptor, concepto)',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: showAdvancedFields,
                              onChanged: (val) {
                                setState(() {
                                  showAdvancedFields = val;
                                });
                              },
                              activeThumbColor: theme.colorScheme.tertiary,
                            ),
                            CounterpartySection(
                              isIssued: direction == InvoiceDirection.issued,
                              theme: theme,
                              label:
                                  direction == InvoiceDirection.issued
                                      ? 'Cliente'
                                      : 'Proveedor',
                              nameController:
                                  direction == InvoiceDirection.issued
                                      ? receiverController
                                      : issuerController,
                              receiverTaxIdController: receiverTaxIdController,
                              receiverAddressController:
                                  receiverAddressController,
                              issuerTaxIdController: issuerTaxIdController,
                              issuerAddressController: issuerAddressController,
                              showAdvancedFields: showAdvancedFields,
                              suggestions:
                                  (direction == InvoiceDirection.issued)
                                      ? filteredClients
                                          .map((c) => c.name)
                                          .toList()
                                      : filteredSuppliers
                                          .map((s) => s.name)
                                          .toList(),
                              onChanged: (value) {
                                if (direction == InvoiceDirection.issued) {
                                  onClientChanged(value);
                                } else {
                                  onSupplierChanged(value);
                                }
                              },
                              onSubmitted: (value) {
                                if (direction == InvoiceDirection.issued) {
                                  unawaited(onClientSubmitted(value));
                                } else {
                                  unawaited(onSupplierSubmitted(value));
                                }
                              },
                              onTapSuggestion: (index) {
                                if (direction == InvoiceDirection.issued) {
                                  selectClient(filteredClients[index]);
                                } else {
                                  selectSupplier(filteredSuppliers[index]);
                                }
                              },
                              invoiceNumberController: invoiceNumberController,
                              onInvoiceNumberChanged:
                                  (value) => setState(
                                    () => invoiceNumber = normalizeText(value),
                                  ),
                              onInvoiceNumberSaved:
                                  (value) => invoiceNumber = value,
                              onReceiverTaxIdChanged:
                                  (value) => setState(
                                    () => receiverTaxId = normalizeText(value),
                                  ),
                              onReceiverAddressChanged:
                                  (value) => setState(
                                    () =>
                                        receiverAddress = normalizeText(value),
                                  ),
                              onIssuerTaxIdChanged:
                                  (value) => setState(
                                    () => issuerTaxId = normalizeText(value),
                                  ),
                              onIssuerAddressChanged:
                                  (value) => setState(
                                    () => issuerAddress = normalizeText(value),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mostrar mis datos'),
                    value: _showSelfSummaryCard,
                    onChanged: (value) {
                      setState(() => _showSelfSummaryCard = value);
                    },
                    dense: true,
                  ),
                  if (_showSelfSummaryCard)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child:
                          selfEmployedUser != null
                              ? SelfSummaryCard(
                                direction: direction,
                                user: selfEmployedUser!,
                                theme: theme,
                              )
                              : SelfSummarySkeleton(theme: theme),
                    ),
                  const SizedBox(height: 16),
                  // Concepto/Pedido + sincro de importes con el mixin
                  ItemsAmountBinder(
                    itemsMode: _itemsMode,
                    toggleItemsMode: toggleItemsMode,
                    conceptController: conceptController,
                    onTuplesChanged:
                        (tuples) => syncAmountFromItemTuples(tuples),
                    onConceptTextChanged:
                        (text) => setState(() {
                          if (_itemsMode) {
                            concept = text;
                          }
                        }),
                  ),
                  const SizedBox(height: 24),

                  if (invoiceImage != null)
                    Column(
                      children: [
                        Image.file(invoiceImage!, height: 150),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => setState(() => invoiceImage = null),
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.onSurface,
                          ),
                          label: const Text('Eliminar imagen'),
                        ),
                      ],
                    ),

                  // Sección de importes desacoplada
                  AmountSection(
                    amountController: amountController,
                    ivaController: ivaController,
                    amount: amount,
                    iva: iva,
                    vatRate: vatRate,
                    includeIva: isAmountIncludingIva,
                    onAmountChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      setState(() {
                        amount = parsed ?? 0.0;
                        updateIva();
                      });
                    },
                    onIncludeIvaChanged: (val) {
                      setState(() {
                        isAmountIncludingIva = val;
                        updateIva();
                      });
                    },
                    onVatRateChanged: (r) {
                      setState(() {
                        vatRate = r;
                        updateIva();
                      });
                    },
                    onIvaChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      setState(() {
                        iva = parsed ?? 0.0;
                        updateIva();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  // Botones en fila
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: selectDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: const Text(
                            'Fecha',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text(
                            'Escaner',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        // Concepto por items ya sincronizado desde ItemsAmountBinder
                        formKey.currentState!.save();
                        submitInvoice();
                        Navigator.pop(context);
                      }
                    },
                    // icon: const Icon(Icons.share),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Guardar', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
