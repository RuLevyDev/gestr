import 'dart:io';
import 'package:gestr/data/ocr/ocr_service.dart';
import 'package:gestr/domain/entities/ocr_invoice_data.dart';
import 'package:gestr/domain/entities/ocr_line_item.dart';
import 'package:gestr/domain/repositories/ocr/ocr_repository.dart';
import 'package:intl/intl.dart';

class _VatInfo {
  final double? amount;
  final double? rate;
  const _VatInfo({this.amount, this.rate});
}

class _IndexedValue {
  final int index;
  final String value;
  const _IndexedValue({required this.index, required this.value});
}

const List<String> _issuerKeywords = <String>[
  'emisor',
  'issuer',
  'proveedor',
  'supplier',
];
const List<String> _receiverKeywords = <String>[
  'receptor',
  'receiver',
  'cliente',
  'customer',
];

/// ImplementaciA3n del [OcrRepository] que utiliza [OcrService]
/// para extraer y normalizar la informaciA3n de una imagen.
class OcrRepositoryImpl implements OcrRepository {
  final OcrService _service;

  OcrRepositoryImpl(this._service);

  @override
  Future<OcrInvoiceData> extractData(File image) async {
    final rawText = await _service.processImage(image);
    // ignore: avoid_print
    print('[OCR] Raw text lines: ${rawText.split('\n').length}');

    final normalized = _normalize(rawText);
    final lines =
        normalized
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
    // ignore: avoid_print
    print('[OCR] Normalized lines: ${lines.length}');

    // TAtulo: primera lAnea no numArica, o emisor si existe
    String? title;
    if (lines.isNotEmpty) {
      title = lines.firstWhere(
        (l) => !RegExp(r'^[-a$0-9 ,.]+$').hasMatch(l),
        orElse: () => lines.first,
      );
    }

    // Totales: intenta obtener base, iva y total
    double? baseAmount = _extractAmountByKeywords(lines, [
      'base imponible',
      'base',
      'subtotal',
      'neto',
    ]);
    var vatInfo = _extractVat(lines);
    double? totalAmount =
        _extractAmountByKeywords(lines, [
          'total',
          'total a pagar',
          'importe total',
          'total factura',
        ]) ??
        _extractBestAmount(lines, normalized);

    // Si no hay suficientes datos, intenta el patrA3n en dos lAneas (cabecera y valores)
    if (baseAmount == null || vatInfo.amount == null || totalAmount == null) {
      final adj = _extractTotalsFromAdjacentLines(lines);
      baseAmount ??= adj.base;
      totalAmount ??= adj.total;
      vatInfo = _VatInfo(amount: vatInfo.amount ?? adj.vat, rate: vatInfo.rate);
    }

    // Calcular faltantes si posible
    double? amount = baseAmount;
    double? vatAmount = vatInfo.amount;
    if (amount == null && totalAmount != null && vatAmount != null) {
      amount = (totalAmount - vatAmount).clamp(0, double.infinity);
    }
    if (vatAmount == null && amount != null && totalAmount != null) {
      vatAmount = (totalAmount - amount).clamp(0, double.infinity);
    }
    if (amount == null && totalAmount != null && vatInfo.rate != null) {
      // Si conocemos el porcentaje, aproxima base: total / (1+rate)
      final r = vatInfo.rate! / 100.0;
      amount = (totalAmount / (1 + r));
      vatAmount ??= totalAmount - amount;
    }

    // Fecha: soporta dd/MM/yyyy, dd-MM-yyyy, yyyy-MM-dd, yyyy/MM/dd
    final date = _extractDate(normalized);

    // Campos adicionales
    final issuer = normalizeText(
      _extractField(normalized, ['Emisor', 'Issuer', 'Proveedor']),
    );
    final receiver = normalizeText(
      _extractField(normalized, ['Receptor', 'Receiver', 'Cliente']),
    );
    final concept = normalizeText(
      _extractField(normalized, [
        'Concepto',
        'Concept',
        'Descripcion',
        'Descripcion',
      ]),
    );

    final invoiceNumber = normalizeText(_extractInvoiceNumber(lines));
    final taxMatches = _gatherTaxIdMatches(lines);
    final addressMatches = _gatherAddressMatches(lines);
    final consumedTaxIndexes = <int>{};
    final consumedAddressIndexes = <int>{};

    final issuerTaxId = normalizeText(
      _extractField(normalized, [
            'NIF Emisor',
            'CIF Emisor',
            'VAT Issuer',
            'Tax Id Supplier',
          ]) ??
          _valueForContext(
            taxMatches,
            lines,
            _issuerKeywords,
            consumedTaxIndexes,
          ),
    );
    final receiverTaxId = normalizeText(
      _extractField(normalized, [
            'NIF Receptor',
            'CIF Receptor',
            'VAT Receiver',
            'NIF Cliente',
          ]) ??
          _valueForContext(
            taxMatches,
            lines,
            _receiverKeywords,
            consumedTaxIndexes,
          ),
    );

    final issuerAddress = normalizeText(
      _extractField(normalized, [
            'Direccion Emisor',
            'Direccion Emisor',
            'Domicilio Emisor',
            'Address Issuer',
          ]) ??
          _valueForContext(
            addressMatches,
            lines,
            _issuerKeywords,
            consumedAddressIndexes,
          ),
    );
    final receiverAddress = normalizeText(
      _extractField(normalized, [
            'Direccion Receptor',
            'Direccion Receptor',
            'Domicilio Receptor',
            'Direccion Cliente',
            'Direccion Cliente',
            'Address Receiver',
          ]) ??
          _valueForContext(
            addressMatches,
            lines,
            _receiverKeywords,
            consumedAddressIndexes,
          ),
    );

    final items = _extractItems(lines);

    return OcrInvoiceData(
      title: title,
      invoiceNumber: invoiceNumber,
      amount: amount,
      vatAmount: vatAmount,
      vatRate: vatInfo.rate,
      totalAmount: totalAmount,
      date: date,
      issuer: issuer,
      issuerTaxId: issuerTaxId,
      issuerAddress: issuerAddress,
      receiver: receiver,
      receiverTaxId: receiverTaxId,
      receiverAddress: receiverAddress,
      concept: concept,
      items: items,
    );
  }

  String? normalizeText(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _extractInvoiceNumber(List<String> lines) {
    final patterns = <RegExp>[
      RegExp(
        r'(?:factura|invoice)[^0-9a-z]*?(?:n[oo]|no|number|num(?:ero)?|#)?[:#\-\s]*([A-Za-z0-9][A-Za-z0-9\-\./]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'^n[oo\.]?[:#\-\s]*([A-Za-z0-9][A-Za-z0-9\-\./]+)$',
        caseSensitive: false,
      ),
    ];
    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final value = match.group(1)?.trim();
          if (value != null && value.isNotEmpty) {
            return value;
          }
        }
      }
    }
    return null;
  }

  List<_IndexedValue> _gatherTaxIdMatches(List<String> lines) {
    final matches = <_IndexedValue>[];
    final regex = RegExp(
      r'(?:nif|cif|vat|tax\s*id|id\s*fiscal)[^A-Za-z0-9]*([A-Za-z0-9][A-Za-z0-9\-\./]*)',
      caseSensitive: false,
    );
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = regex.firstMatch(line);
      if (match != null) {
        var value = match.group(1)?.trim() ?? '';
        if (value.isEmpty && i + 1 < lines.length) {
          value = lines[i + 1].trim();
        }
        value = value.replaceAll(RegExp(r'[^A-Za-z0-9\-\./]'), '');
        if (value.isNotEmpty) {
          matches.add(_IndexedValue(index: i, value: value));
        }
      }
    }
    return matches;
  }

  List<_IndexedValue> _gatherAddressMatches(List<String> lines) {
    final matches = <_IndexedValue>[];
    final regex = RegExp(
      r'(?:direccion|direccion|domicilio|address)[:#\-\s]*([^$]*)',
      caseSensitive: false,
    );
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = regex.firstMatch(line);
      if (match != null) {
        var value = match.group(1)?.trim() ?? '';
        if (value.isEmpty && i + 1 < lines.length) {
          final next = lines[i + 1].trim();
          if (next.isNotEmpty && !next.toLowerCase().contains('factura')) {
            value = next;
          }
        }
        if (value.isNotEmpty) {
          matches.add(_IndexedValue(index: i, value: value));
        }
      }
    }
    return matches;
  }

  String? _valueForContext(
    List<_IndexedValue> matches,
    List<String> lines,
    List<String> keywords,
    Set<int> consumed,
  ) {
    for (final match in matches) {
      if (consumed.contains(match.index)) continue;
      if (_hasKeywordNearby(lines, match.index, keywords)) {
        consumed.add(match.index);
        return match.value;
      }
    }
    for (final match in matches) {
      if (consumed.add(match.index)) {
        return match.value;
      }
    }
    return null;
  }

  bool _hasKeywordNearby(List<String> lines, int index, List<String> keywords) {
    final lowered = keywords.map((k) => k.toLowerCase()).toList();
    for (var offset = -2; offset <= 2; offset++) {
      final idx = index + offset;
      if (idx < 0 || idx >= lines.length) continue;
      final lowerLine = lines[idx].toLowerCase();
      for (final keyword in lowered) {
        if (lowerLine.contains(keyword)) {
          return true;
        }
      }
    }
    return false;
  }

  String? _extractField(String text, List<String> labels) {
    final lines = text.split('\n');
    for (final label in labels) {
      final lower = label.toLowerCase();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lline = line.toLowerCase();
        if (lline.startsWith(lower)) {
          final parts = line.split(RegExp('[:|-]'));
          if (parts.length > 1) {
            return parts.sublist(1).join(':').trim();
          }
          // Si no hay separador, intenta tomar la siguiente lAnea como valor
          if (i + 1 < lines.length) {
            final next = lines[i + 1].trim();
            if (next.isNotEmpty &&
                !labels.any(
                  (l) => next.toLowerCase().startsWith(l.toLowerCase()),
                )) {
              return next;
            }
          }
        }
      }
    }
    return null;
  }

  String _normalize(String text) {
    return text
        .replaceAll('\r', '')
        .replaceAll(RegExp(r'[\t]+'), ' ')
        .replaceAll(RegExp(' +'), ' ');
  }

  DateTime? _extractDate(String text) {
    final patterns = <String, String>{
      r'(\d{2})[/-](\d{2})[/-](\d{4})': 'dd/MM/yyyy',
      r'(\d{4})[/-](\d{2})[/-](\d{2})': 'yyyy/MM/dd',
      r'(\d{2})[.](\d{2})[.](\d{4})': 'dd.MM.yyyy',
    };
    for (final entry in patterns.entries) {
      final m = RegExp(entry.key).firstMatch(text);
      if (m != null) {
        try {
          return DateFormat(entry.value).parseStrict(m.group(0)!);
        } catch (_) {}
      }
    }
    return null;
  }

  double? _extractBestAmount(List<String> lines, String text) {
    final amountRe = RegExp(r'(?<!\d)(?:\d{1,3}(?:[.,]\d{3})*[.,]\d{2})(?!\d)');

    double? parseAmount(String s) {
      // Normaliza 1.234,56 o 1,234.56 a 1234.56
      final cleaned = s.replaceAll(' ', '');
      final hasComma = cleaned.contains(',');
      final hasDot = cleaned.contains('.');
      String normalized = cleaned;
      if (hasComma && hasDot) {
        // Asume el Aoltimo separador es decimal; elimina el otro
        final lastComma = cleaned.lastIndexOf(',');
        final lastDot = cleaned.lastIndexOf('.');
        if (lastComma > lastDot) {
          normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
        } else {
          normalized = cleaned.replaceAll(',', '');
        }
      } else if (hasComma) {
        normalized = cleaned.replaceAll(',', '.');
      }
      return double.tryParse(normalized);
    }

    // 1) Busca en lAneas con keywords de totales
    final keywords = [
      'total',
      'importe',
      'a pagar',
      'total a pagar',
      'total factura',
    ];
    final candidateValues = <double>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (keywords.any((k) => lower.contains(k))) {
        for (final m in amountRe.allMatches(line)) {
          final v = parseAmount(m.group(0)!);
          if (v != null) candidateValues.add(v);
        }
      }
    }
    if (candidateValues.isNotEmpty) {
      candidateValues.sort();
      return candidateValues.last; // el mayor suele ser el total
    }

    // 2) Fallback: mayor nAomero con dos decimales en todo el texto
    final matches =
        amountRe
            .allMatches(text)
            .map((m) => parseAmount(m.group(0)!))
            .whereType<double>()
            .toList();
    if (matches.isNotEmpty) {
      matches.sort();
      return matches.last;
    }
    return null;
  }

  double? _extractAmountByKeywords(List<String> lines, List<String> keywords) {
    final amountRe = RegExp(r'(?<!\d)(?:\d{1,3}(?:[.,]\d{3})*[.,]\d{2})(?!\d)');
    double? best;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (keywords.any((k) => lower.contains(k))) {
        for (final m in amountRe.allMatches(line)) {
          final v = _toDouble(m.group(0)!);
          if (v != null) {
            if (best == null || v > best) best = v; // coge el mayor de la lAnea
          }
        }
      }
    }
    return best;
  }

  ({double? base, double? vat, double? total}) _extractTotalsFromAdjacentLines(
    List<String> lines,
  ) {
    // Busca una lAnea tipo "Subtotal Iva Total" y toma los 2-3 importes de la siguiente
    final headerRe = RegExp(r'(subtotal|base|iva|impuesto|total)');
    final amountRe = RegExp(r'(?<!\d)(?:\d{1,3}(?:[.,]\d{3})*[.,]\d{2})(?!\d)');
    for (int i = 0; i < lines.length - 1; i++) {
      final h = lines[i].toLowerCase();
      if (headerRe.hasMatch(h) &&
          (h.contains('subtotal') || h.contains('base'))) {
        final next = lines[i + 1];
        final ms = amountRe.allMatches(next).toList();
        if (ms.isNotEmpty) {
          final nums =
              ms
                  .map((m) => _toDouble(m.group(0)!))
                  .whereType<double>()
                  .toList();
          if (nums.length == 3) {
            return (base: nums[0], vat: nums[1], total: nums[2]);
          } else if (nums.length == 2) {
            // base y total; IVA = total - base
            final base = nums[0];
            final total = nums[1];
            return (base: base, vat: (total - base), total: total);
          }
        }
      }
    }
    return (base: null, vat: null, total: null);
  }

  double? _toDouble(String s) {
    var cleaned = s.replaceAll('EUR', '').replaceAll('a', '').trim();
    cleaned = cleaned.replaceAll(' ', '');
    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');
    if (hasComma && hasDot) {
      final lastComma = cleaned.lastIndexOf(',');
      final lastDot = cleaned.lastIndexOf('.');
      if (lastComma > lastDot) {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (hasComma) {
      cleaned = cleaned.replaceAll(',', '.');
    }
    return double.tryParse(cleaned);
  }

  _VatInfo _extractVat(List<String> lines) {
    double? amount;
    double? rate;
    final amountRe = RegExp(r'(?<!\d)(?:\d{1,3}(?:[.,]\d{3})*[.,]\d{2})(?!\d)');
    final rateRe = RegExp(r'(\d{1,2})(?:[,\.]\d+)?\s*%');
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('iva') ||
          lower.contains('vat') ||
          lower.contains('impuesto')) {
        // tasa
        final rm = rateRe.firstMatch(line);
        if (rm != null) {
          rate = double.tryParse(rm.group(1)!);
        }
        // amount
        for (final m in amountRe.allMatches(line)) {
          final v = _toDouble(m.group(0)!);
          if (v != null) {
            amount = v;
          }
        }
      }
    }
    return _VatInfo(amount: amount, rate: rate);
  }

  List<OcrLineItem> _extractItems(List<String> lines) {
    final items = <OcrLineItem>[];

    int? toInt(String s) => int.tryParse(s.trim());
    double? toDouble(String s) {
      var cleaned = s.trim();
      cleaned = cleaned.replaceAll(RegExp(r'[^0-9.,]'), '');
      final hasComma = cleaned.contains(',');
      final hasDot = cleaned.contains('.');
      if (hasComma && hasDot) {
        final lastComma = cleaned.lastIndexOf(',');
        final lastDot = cleaned.lastIndexOf('.');
        if (lastComma > lastDot) {
          cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
        } else {
          cleaned = cleaned.replaceAll(',', '');
        }
      } else if (hasComma) {
        cleaned = cleaned.replaceAll(',', '.');
      }
      return double.tryParse(cleaned);
    }

    final patterns = <RegExp, List<int>>{
      // 1x Producto (precio en lAnea siguiente)
      RegExp(r'^\s*(\d+)\s*[xXA*]\s*([^\d].*?)\s*$'): [1, 2, 0],
      // 2 x Manzana 1,50  -> qty(1), product(2), price(3)
      RegExp(r'^\s*(\d+)\s*[xXA*]\s*([^\d].*?)\s+([\d.,]+)\s*$'): [1, 2, 3],
      // Manzana 2 x 1,50 -> product(1), qty(2), price(3)
      RegExp(r'^\s*([^\d].*?)\s+(\d+)\s*[xXA*]\s*([\d.,]+)\s*$'): [2, 1, 3],
      // Manzana    2    1,50 -> product(1), qty(2), price(3)
      RegExp(r'^\s*([^\d].*?)\s{2,}(\d+)\s+([\d.,]+)\s*$'): [2, 1, 3],
      // 2 Manzana    1,50 -> qty(1), product(2), price(3)
      RegExp(r'^\s*(\d+)\s+([^\d].*?)\s{2,}([\d.,]+)\s*$'): [1, 2, 3],
      // Manzana .... 1,50 -> product(1), price(2) (qty=1)
      RegExp(r'^\s*([^\d].*?)\s+[.Aa\- ]{2,}\s*([\d.,]+)\s*$'): [-1, 1, 2],
      // Manzana 1,50 -> product(1), price(2) (qty=1)
      RegExp(r'^\s*([^\d].*?)\s+([\d.,]+)\s*$'): [-1, 1, 2],
    };

    // Recorre con Andice para poder mirar la siguiente lAnea
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (line.startsWith('+')) continue; // ignora modificadores

      bool captured = false;
      for (final entry in patterns.entries) {
        final m = entry.key.firstMatch(line);
        if (m != null) {
          final map = entry.value; // [qtyIndex, productIndex, priceIndex]
          final qtyIdx = map[0];
          final productIdx = map[1];
          final priceIdx = map[2];

          final qty = qtyIdx > 0 ? (toInt(m.group(qtyIdx)!) ?? 1) : 1;
          final product = m.group(productIdx)!.trim();
          double? price;

          // Si el patrA3n incluye precio, tA3malo
          if (priceIdx > 0) {
            price = toDouble(m.group(priceIdx) ?? '');
          }
          // Si no hay precio en la misma lAnea, busca en la siguiente una lAnea de solo precio
          if (price == null || price == 0) {
            if (i + 1 < lines.length) {
              final next = lines[i + 1].trim();
              final onlyPrice = RegExp(r'^\s*[a$]?[\s\d.,]+\s*(?:eur|a)?\s*$');
              if (onlyPrice.hasMatch(next)) {
                price = toDouble(next);
                i++; // consumir la lAnea de precio
              }
            }
          }

          if (product.isNotEmpty && (price ?? 0) > 0) {
            items.add(
              OcrLineItem(product: product, quantity: qty, price: price!),
            );
            captured = true;
            break;
          }
        }
      }
      if (captured) continue;
    }

    return items;
  }
}
