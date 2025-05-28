import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_bloc.dart';
import 'package:gestr/app/invoices/bloc/invoice_state.dart';
import 'package:gestr/core/utils/background_light.dart';
import 'package:gestr/core/utils/dialog_background.dart';
import 'package:gestr/domain/entities/invoice_model.dart';

class InvoiceDetailPage extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: isDark ? const DialogBackground() : const BackgroundLight(),
        ),
        Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              "Detalle de factura",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            backgroundColor: Colors.transparent,
          ),
          body: BlocBuilder<InvoiceBloc, InvoiceState>(
            builder: (context, state) {
              if (state is InvoiceLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is InvoiceLoaded) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text("Fecha: ${_formatDate(invoice.date)}"),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        invoice.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),

                      // Emisor y receptor
                      _buildInfoGrid([
                        if (invoice.issuer != null)
                          _InfoTile(title: "Emisor", value: invoice.issuer!),
                        if (invoice.receiver != null)
                          _InfoTile(
                            title: "Receptor",
                            value: invoice.receiver!,
                          ),
                      ], context),

                      if (invoice.concept != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Concepto:",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(invoice.concept!),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      _buildInfoGrid([
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Base imponible: ${invoice.netAmount.toStringAsFixed(2)}€",
                            ),

                            Container(
                              width: 2,
                              height: 40,
                              decoration: BoxDecoration(color: Colors.pink),
                            ),

                            Text("IVA: ${invoice.iva.toStringAsFixed(2)}€"),

                            Container(
                              width: 2,
                              height: 40,
                              decoration: BoxDecoration(color: Colors.pink),
                            ),

                            Text("Total: ${invoice.total.toStringAsFixed(2)}€"),
                          ],
                        ),
                      ], context),

                      const SizedBox(height: 24),
                      Center(child: Text("Estado: ${invoice.status.labelEs}")),

                      // Imagenes
                      if (invoice.imageUrl != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          "Imagen adjunta:",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(invoice.imageUrl!),
                        ),
                      ],
                      if (invoice.image != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          "Imagen local cargada (no subida):",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(invoice.image!),
                        ),
                      ],
                    ],
                  ),
                );
              } else if (state is InvoiceError) {
                return Center(child: Text("Error: ${state.message}"));
              }
              return const Center(child: Text("No se encontró la factura."));
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  Widget _buildInfoGrid(List<Widget> items, BuildContext context) {
    return Wrap(
      spacing: MediaQuery.of(context).size.width / 10,
      runSpacing: 1,
      children: items,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
