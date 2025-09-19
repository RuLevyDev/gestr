import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';

class SiiMapper {
  const SiiMapper._();

  static Map<String, dynamic> mapIssued(Invoice inv, SelfEmployedUser me) {
    final opDate = inv.operationDate ?? inv.date;
    final number = _resolveNumber(inv);
    final lines = inv.taxLines ?? _deriveSingle(inv);
    final receiverIdType = _resolveIdType(
      inv.receiverIdType,
      inv.receiverTaxId,
    );
    final receiverCountry = _resolveCountry(
      inv.receiverCountryCode,
      inv.receiverTaxId,
    );
    return <String, dynamic>{
      'tipoFactura': _resolveTipoFactura(inv),
      'fechaExpedicion': _fmtDate(inv.date),
      'fechaOperacion': _fmtDate(opDate),
      'numeroFactura': number,
      'emisor': {
        'tipoId': me.idType,
        'idFiscal': me.dni,
        'nombre': me.fullName,
        'pais': me.countryCode,
      },
      'receptor': {
        if (receiverIdType != null) 'tipoId': receiverIdType,
        'idFiscal': inv.receiverTaxId,
        'nombre': inv.receiver,
        if (receiverCountry != null) 'pais': receiverCountry,
      },
      'desgloseIva': [
        for (final t in lines)
          {
            'tipo': _pct(t.rate),
            'base': _round2(t.base),
            'cuota': _round2(t.quota),
            if (t.recargoEquivalencia != null)
              'recargoEquivalencia': _round2(t.recargoEquivalencia!),
          },
      ],
      'inversionSujetoPasivo': inv.reverseCharge == true,
      'exencion': inv.exemptionType,
      'moneda': inv.currency,
    };
  }

  static Map<String, dynamic> mapReceived(Invoice inv, SelfEmployedUser me) {
    final opDate = inv.operationDate ?? inv.date;
    final number = _resolveNumber(inv);
    final lines = inv.taxLines ?? _deriveSingle(inv);
    final issuerIdType = _resolveIdType(inv.issuerIdType, inv.issuerTaxId);
    final issuerCountry = _resolveCountry(
      inv.issuerCountryCode,
      inv.issuerTaxId,
    );
    return <String, dynamic>{
      'tipoFactura': _resolveTipoFactura(inv),
      'fechaExpedicion': _fmtDate(inv.date),
      'fechaOperacion': _fmtDate(opDate),
      'numeroFactura': number,
      'emisor': {
        if (issuerIdType != null) 'tipoId': issuerIdType,
        'idFiscal': inv.issuerTaxId,
        'nombre': inv.issuer,
        if (issuerCountry != null) 'pais': issuerCountry,
      },
      'receptor': {
        'tipoId': me.idType,
        'idFiscal': me.dni,
        'nombre': me.fullName,
        'pais': me.countryCode,
      },

      'desgloseIva': [
        for (final t in lines)
          {
            'tipo': _pct(t.rate),
            'base': _round2(t.base),
            'cuota': _round2(t.quota),
            if (t.recargoEquivalencia != null)
              'recargoEquivalencia': _round2(t.recargoEquivalencia!),
          },
      ],
      'inversionSujetoPasivo': inv.reverseCharge == true,
      'exencion': inv.exemptionType,
      'moneda': inv.currency,
    };
  }

  static String _resolveNumber(Invoice inv) {
    if (inv.series != null && inv.sequentialNumber != null) {
      return '${inv.series}-${inv.sequentialNumber}';
    }
    return inv.invoiceNumber ?? '';
  }

  static List<TaxLine> _deriveSingle(Invoice inv) {
    final base = inv.netAmount;
    final quota = inv.iva;
    double rate;
    if (inv.vatRate != null && inv.vatRate! > 0) {
      rate = inv.vatRate!;
    } else {
      rate = base > 0 ? (quota / base) : 0.0;
    }
    return [TaxLine(rate: rate, base: base, quota: quota)];
  }

  static String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static double _pct(double rate) {
    return (rate <= 1.0) ? (rate * 100.0) : rate;
  }

  static double _round2(double v) => double.parse(v.toStringAsFixed(2));

  static String _resolveTipoFactura(Invoice inv) {
    // Por ahora tratamos todas como factura completa normal (F1)
    return 'F1';
  }

  static String? _resolveIdType(String? raw, String? taxId) {
    final trimmed = raw?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    if (taxId == null || taxId.trim().isEmpty) {
      return null;
    }
    return 'NIF';
  }

  static String? _resolveCountry(String? raw, String? taxId) {
    final trimmed = raw?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    if (taxId == null || taxId.trim().isEmpty) {
      return null;
    }
    return 'ES';
  }
}
