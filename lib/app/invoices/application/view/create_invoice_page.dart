import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gestr/app/invoices/application/viewmodel/create_invoice_viewmodel.dart';
import 'package:gestr/app/relationships/clients/application/view/create_client_sheet.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
import 'package:gestr/domain/entities/client.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:gestr/domain/usecases/client/client_usecases.dart';
import 'package:provider/provider.dart';
import 'package:gestr/domain/entities/supplier.dart';
import 'package:gestr/domain/usecases/supplier/supplier_usecases.dart';
import 'package:gestr/app/relationships/suppliers/application/view/create_supplier_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage>
    with CreateInvoiceViewModelMixin {
  late final ClientUseCases _clientUseCases;
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  Timer? _debounce;
  late final SupplierUseCases _supplierUseCases;
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];

  @override
  void initState() {
    super.initState();
    _clientUseCases = context.read<ClientUseCases>();
    _loadClients();
    _supplierUseCases = context.read<SupplierUseCases>();
    _loadSuppliers();
  }

  Future<void> _loadClients() async {
    final list = await _clientUseCases.fetch(userId);
    setState(() {
      _clients = list;
    });
  }

  Future<void> _loadSuppliers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final list = await _supplierUseCases.fetch(uid);
    setState(() {
      _suppliers = list;
    });
  }

  void _onClientChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = value.toLowerCase();
      setState(() {
        receiver = value;
        _filteredClients =
            _clients.where((c) => c.name.toLowerCase().contains(q)).toList();
      });
    });
  }

  void _selectClient(Client c) {
    setState(() {
      receiverController.text = c.name;
      receiver = c.name;
      receiverTaxId = c.taxId;
      receiverAddress = c.fiscalAddress;
      _filteredClients = [];
    });
  }

  Future<void> _onClientSubmitted(String value) async {
    final match = _clients.firstWhere(
      (c) => c.name.toLowerCase() == value.toLowerCase(),
      orElse: () => const Client(name: ''),
    );
    if (match.id == null || match.name.isEmpty) {
      final should = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cliente no encontrado'),
              content: Text('¿Deseas registrar "$value" como nuevo cliente?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sí'),
                ),
              ],
            ),
      );
      if (!mounted) return;
      if (should == true) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => CreateClientSheet(initialName: value),
        );
        await _loadClients();
        final created = _clients.firstWhere(
          (c) => c.name.toLowerCase() == value.toLowerCase(),
          orElse: () => const Client(name: ''),
        );
        if (created.id != null) {
          _selectClient(created);
        }
      } else {
        setState(() {
          receiver = value;
          receiverTaxId = null;
          receiverAddress = null;
        });
      }
    } else {
      _selectClient(match);
    }
  }

  void _onSupplierChanged(String value) {
    setState(() {
      issuer = value;
      _filteredSuppliers =
          _suppliers
              .where((s) => s.name.toLowerCase().contains(value.toLowerCase()))
              .toList();
    });
  }

  void _selectSupplier(Supplier s) {
    setState(() {
      issuerController.text = s.name;
      issuer = s.name;
      _filteredSuppliers = [];
    });
  }

  Future<void> _onSupplierSubmitted(String value) async {
    final match = _suppliers.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => const Supplier(name: ''),
    );
    if (match.id == null || match.name.isEmpty) {
      final should = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Proveedor no encontrado'),
              content: Text('¿Deseas registrar "$value" como nuevo proveedor?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sí'),
                ),
              ],
            ),
      );
      if (!mounted) return;
      if (should == true) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => CreateSupplierSheet(initialName: value),
        );
        await _loadSuppliers();
        final created = _suppliers.firstWhere(
          (s) => s.name.toLowerCase() == value.toLowerCase(),
          orElse: () => const Supplier(name: ''),
        );
        if (created.id != null) {
          _selectSupplier(created);
        }
      } else {
        setState(() {
          issuer = value;
        });
      }
    } else {
      _selectSupplier(match);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

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
                  // Container cristal translúcido morado para título hasta separador
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
                            // Mostrar fecha encima del título a la derecha
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Fecha:  ${DateFormat('yyyy-MM-dd').format(invoiceDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            // Campo título
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Título',
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
                            // Switch para mostrar datos avanzados justo debajo del título
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
                            TextFormField(
                              controller: receiverController,
                              decoration: const InputDecoration(
                                labelText: 'Receptor',
                              ),
                              onChanged: _onClientChanged,
                              onFieldSubmitted: _onClientSubmitted,
                            ),
                            if (_filteredClients.isNotEmpty)
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 150,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView(
                                  shrinkWrap: true,
                                  children:
                                      _filteredClients
                                          .map(
                                            (c) => ListTile(
                                              title: Text(c.name),
                                              onTap: () => _selectClient(c),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            if (receiverTaxId != null ||
                                receiverAddress != null) ...[
                              const SizedBox(height: 8),
                              if (receiverTaxId != null)
                                Text(
                                  'NIF: $receiverTaxId',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (receiverAddress != null)
                                Text(
                                  receiverAddress!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                            if (showAdvancedFields) ...[
                              TextFormField(
                                controller: issuerController,
                                decoration: InputDecoration(
                                  labelText: 'Emisor',
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                onChanged: _onSupplierChanged,
                                onFieldSubmitted: _onSupplierSubmitted,
                                onSaved: (value) => issuer = value,
                              ),
                              if (_filteredSuppliers.isNotEmpty)
                                Container(
                                  height: 150,
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ListView(
                                    children:
                                        _filteredSuppliers
                                            .map(
                                              (s) => ListTile(
                                                title: Text(s.name),
                                                onTap: () => _selectSupplier(s),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                              const SizedBox(height: 12),

                              const SizedBox(height: 12),
                              TextFormField(
                                controller: conceptController,
                                decoration: InputDecoration(
                                  labelText: 'Concepto',
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                maxLines: 3,
                                onSaved: (value) => concept = value,
                              ),
                              const SizedBox(height: 24),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(
                    color: Colors.tealAccent,
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 8),
                  // Container cristal translúcido morado para el resto (importe, switches, botones...)
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
                            // Switch importe incluye IVA
                            SwitchListTile(
                              title: const Text('El importe neto incluye IVA'),
                              value: isAmountIncludingIva,
                              onChanged: (val) {
                                setState(() {
                                  isAmountIncludingIva = val;
                                  updateIva();
                                });
                              },
                              activeThumbColor: theme.colorScheme.tertiary,
                            ),
                            // Campo importe neto
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Importe neto (€)',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              // style: const TextStyle(color: Colors.white),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              initialValue:
                                  amount > 0 ? amount.toStringAsFixed(2) : null,
                              validator: (value) {
                                if (value == null) return 'Requerido';
                                final d = double.tryParse(value);
                                if (d == null || d < 0) return 'Valor inválido';
                                return null;
                              },
                              onChanged: (value) {
                                final d = double.tryParse(value);
                                if (d != null) {
                                  setState(() {
                                    amount = d;
                                    if (isAmountIncludingIva) {
                                      updateIva();
                                    }
                                  });
                                }
                              },
                              onSaved: (value) {
                                amount = double.tryParse(value ?? '0') ?? 0;
                                if (isAmountIncludingIva) {
                                  updateIva();
                                }
                              },
                            ),

                            // Campo IVA oculto con Visibility
                            Visibility(
                              visible: !isAmountIncludingIva,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'IVA (€)',
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),

                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                initialValue:
                                    iva > 0 ? iva.toStringAsFixed(2) : '0',
                                enabled: !isAmountIncludingIva,
                                validator: (value) {
                                  if (value == null) return 'Requerido';
                                  final d = double.tryParse(value);
                                  if (d == null || d < 0) {
                                    return 'Valor inválido';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final d = double.tryParse(value);
                                  if (d != null && !isAmountIncludingIva) {
                                    setState(() {
                                      iva = d;
                                    });
                                  }
                                },
                                onSaved: (value) {
                                  iva = double.tryParse(value ?? '0') ?? 0;
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            DropdownButtonFormField<InvoiceStatus>(
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                              ),
                              initialValue: status,
                              dropdownColor: theme.colorScheme.secondary,
                              items:
                                  [InvoiceStatus.pending, InvoiceStatus.sent]
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e.labelEs),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    status = value;
                                    if (status == InvoiceStatus.sent) {
                                      showAdvancedFields = true;
                                      if (selfEmployedUser != null) {
                                        issuerController.text =
                                            selfEmployedUser!.fullName;
                                        issuer = selfEmployedUser!.fullName;
                                      }
                                    }
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 24),

                            if (invoiceImage != null)
                              Column(
                                children: [
                                  Image.file(invoiceImage!, height: 150),
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed:
                                        () =>
                                            setState(() => invoiceImage = null),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    label: const Text('Eliminar imagen'),
                                  ),
                                ],
                              ),

                            // Botones en fila
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: selectDate,
                                    icon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
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
                                  formKey.currentState!.save();
                                  // generateAndSharePdf();
                                  submitInvoice();
                                  Navigator.pop(context);
                                }
                              },
                              // icon: const Icon(Icons.share),
                              label: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Guardar',
                                    style: TextStyle(fontSize: 18),
                                  ),
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}
