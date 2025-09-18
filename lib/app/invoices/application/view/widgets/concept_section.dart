import 'package:flutter/material.dart';
import 'dart:ui';

class ConceptItemRowData {
  final TextEditingController productCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  void dispose() {
    productCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class ConceptSection extends StatelessWidget {
  const ConceptSection({
    super.key,
    required this.itemsMode,
    required this.toggleItemsMode,
    required this.conceptController,
    required this.items,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onItemsChanged,
  });

  final bool itemsMode;
  final VoidCallback toggleItemsMode;
  final TextEditingController conceptController;
  final List<ConceptItemRowData> items;
  final VoidCallback onAddLine;
  final void Function(int index) onRemoveLine;
  final VoidCallback onItemsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.tealAccent.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      itemsMode ? 'Pedido' : 'Concepto',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Tooltip(
                    message:
                        itemsMode ? 'Cambiar a texto libre' : 'Cambiar a tabla de conceptos',
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: itemsMode
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surface.withValues(alpha: 0.7),
                        border: Border.all(
                          color: itemsMode
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: IconButton(
                        tooltip: '',
                        padding: EdgeInsets.zero,
                        onPressed: toggleItemsMode,
                        icon: const Icon(Icons.table_rows_outlined, size: 18),
                        color: itemsMode
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!itemsMode)
                TextFormField(
                  controller: conceptController,
                  decoration: InputDecoration(
                    hintText: 'Detalle del concepto',
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  maxLines: 3,
                )
              else ...[
                // Sin encabezados: solo filas
                for (var i = 0; i < items.length; i++)
                  _ConceptItemRow(
                    data: items[i],
                    onChanged: onItemsChanged,
                    onRemove: () => onRemoveLine(i),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onAddLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir línea'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConceptItemRow extends StatelessWidget {
  const _ConceptItemRow({
    required this.data,
    required this.onChanged,
    required this.onRemove,
  });

  final ConceptItemRowData data;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: TextFormField(
              controller: data.productCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Producto/Servicio',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: data.qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: '1',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: data.priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: '0.00',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}
