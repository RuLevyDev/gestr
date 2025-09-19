import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:gestr/domain/repositories/invoice/invoice_reposiroty.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:meta/meta.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  InvoiceRepositoryImpl(this.firestore, {FirebaseStorage? storage})
    : storage = storage ?? FirebaseStorage.instance;

  // Obtener todas las facturas de un usuario
  @override
  Future<List<Invoice>> getInvoices(String userId) async {
    try {
      final snapshot =
          await firestore
              .collection('users')
              .doc(userId)
              .collection('invoices')
              .orderBy('date', descending: true)
              .get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final invoices = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          var status = _parseStatus(data['status']);
          final date = (data['date'] as Timestamp).toDate();
          final invoiceDate = DateTime(date.year, date.month, date.day);

          if (status == InvoiceStatus.sent && invoiceDate.isBefore(today)) {
            await doc.reference.update({'status': InvoiceStatus.overdue.name});
            status = InvoiceStatus.overdue;
          }

          return Invoice(
            id: doc.id,
            title: data['title'],
            date: date,
            operationDate:
                (data['operationDate'] is Timestamp)
                    ? (data['operationDate'] as Timestamp).toDate()
                    : null,
            netAmount: (data['netAmount'] ?? 0).toDouble(),
            iva: (data['iva'] ?? 0).toDouble(),
            status: status,
            invoiceNumber: data['invoiceNumber'],
            series: data['series'],
            sequentialNumber:
                (data['sequentialNumber'] is int)
                    ? data['sequentialNumber'] as int
                    : (data['sequentialNumber'] is num)
                    ? (data['sequentialNumber'] as num).toInt()
                    : null,
            issuer: data['issuer'],
            issuerTaxId: data['issuerTaxId'],
            issuerAddress: data['issuerAddress'],
            issuerCountryCode: data['issuerCountryCode'],
            issuerIdType: data['issuerIdType'],
            receiver: data['receiver'],
            receiverTaxId: data['receiverTaxId'],
            receiverAddress: data['receiverAddress'],
            receiverCountryCode: data['receiverCountryCode'],
            receiverIdType: data['receiverIdType'],
            concept: data['concept'],
            vatRate: _parseNullableDouble(data['vatRate']),
            currency: (data['currency'] as String?) ?? 'EUR',
            direction: data['direction'] as String?,
            taxLines: _parseTaxLines(data['taxLines']),
            reverseCharge: data['reverseCharge'] as bool?,
            exemptionType: data['exemptionType'] as String?,
            specialRegime: data['specialRegime'] as String?,
            imageUrl: data['imageUrl'],
          );
        }),
      );

      return invoices;
    } catch (e) {
      throw Exception("Error al obtener las facturas: $e");
    }
  }

  // Crear factura para un usuario
  @override
  Future<void> createInvoice(String userId, Invoice invoice) async {
    try {
      String? imageUrl;

      if (invoice.image != null) {
        imageUrl = await _uploadImage(invoice.image!, 'invoices');
      }

      // Derivar campos SII mínimos y numeración
      final direction = invoice.direction ?? 'issued';
      final operationDate = invoice.operationDate ?? invoice.date;
      final taxLines =
          (invoice.taxLines != null && invoice.taxLines!.isNotEmpty)
              ? invoice.taxLines!
              : _deriveSingleTaxLine(invoice);

      String? series = invoice.series;
      int? sequentialNumber = invoice.sequentialNumber;

      if (direction == 'issued') {
        final numbering = await ensureIssuedInvoiceNumbering(
          userId,
          invoice,
          initialSeries: series,
        );
        series = numbering.series;
        sequentialNumber = numbering.sequentialNumber;
      }

      await firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .add({
            'title': invoice.title,
            'date': invoice.date,
            'operationDate': operationDate,
            'netAmount': invoice.netAmount,
            'iva': invoice.iva,
            'status': invoice.status.name,
            'invoiceNumber': invoice.invoiceNumber,
            'series': series,
            'sequentialNumber': sequentialNumber,
            'issuer': invoice.issuer,
            'issuerTaxId': invoice.issuerTaxId,
            'issuerAddress': invoice.issuerAddress,
            'issuerCountryCode': invoice.issuerCountryCode,
            'issuerIdType': invoice.issuerIdType,
            'receiver': invoice.receiver,
            'receiverTaxId': invoice.receiverTaxId,
            'receiverAddress': invoice.receiverAddress,
            'receiverCountryCode': invoice.receiverCountryCode,
            'receiverIdType': invoice.receiverIdType,
            'concept': invoice.concept,
            'vatRate': invoice.vatRate,
            'currency': invoice.currency,
            'direction': direction,
            'taxLines':
                taxLines
                    .map(
                      (t) => {
                        'rate': t.rate,
                        'base': t.base,
                        'quota': t.quota,
                        if (t.recargoEquivalencia != null)
                          'recargoEquivalencia': t.recargoEquivalencia,
                      },
                    )
                    .toList(),
            'reverseCharge': invoice.reverseCharge ?? false,
            'exemptionType': invoice.exemptionType,
            'specialRegime': invoice.specialRegime,
            'imageUrl': imageUrl,
          });
    } catch (e) {
      throw Exception("Error al crear la factura: $e");
    }
  }

  // Eliminar factura de un usuario
  @override
  Future<void> deleteInvoice(String userId, String invoiceId) async {
    try {
      final docRef = firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId);

      final doc = await docRef.get();

      if (doc.exists && doc.data()!['imageUrl'] != null) {
        final imageUrl = doc.data()!['imageUrl'] as String;
        final ref = storage.refFromURL(imageUrl);
        await ref.delete();
      }

      await docRef.delete();
    } catch (e) {
      throw Exception("Error al eliminar la factura: $e");
    }
  }

  // Actualizar factura de un usuario
  @override
  Future<void> updateInvoice(String userId, Invoice invoice) async {
    try {
      final docRef = firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoice.id);

      final doc = await docRef.get();

      String? imageUrl = invoice.imageUrl;

      if (invoice.image != null) {
        if (doc.exists && doc.data()!['imageUrl'] != null) {
          final oldImageUrl = doc.data()!['imageUrl'] as String;
          final oldRef = storage.refFromURL(oldImageUrl);
          await oldRef.delete();
        }

        imageUrl = await _uploadImage(invoice.image!, 'invoices');
      }

      // Mantener campos SII coherentes al actualizar
      final direction =
          invoice.direction ??
          (doc.data()!['direction'] as String? ?? 'issued');
      final operationDate =
          invoice.operationDate ??
          (doc.data()!['operationDate'] as Timestamp?)?.toDate() ??
          invoice.date;
      final taxLines =
          (invoice.taxLines != null && invoice.taxLines!.isNotEmpty)
              ? invoice.taxLines!
              : _deriveSingleTaxLine(invoice);

      await docRef.update({
        'title': invoice.title,
        'date': invoice.date,
        'operationDate': operationDate,
        'netAmount': invoice.netAmount,
        'iva': invoice.iva,
        'status': invoice.status.name,
        'invoiceNumber': invoice.invoiceNumber,
        if (invoice.series != null) 'series': invoice.series,
        if (invoice.sequentialNumber != null)
          'sequentialNumber': invoice.sequentialNumber,
        'issuer': invoice.issuer,
        'issuerTaxId': invoice.issuerTaxId,
        'issuerAddress': invoice.issuerAddress,
        'issuerCountryCode': invoice.issuerCountryCode,
        'issuerIdType': invoice.issuerIdType,
        'receiver': invoice.receiver,
        'receiverTaxId': invoice.receiverTaxId,
        'receiverAddress': invoice.receiverAddress,
        'receiverCountryCode': invoice.receiverCountryCode,
        'receiverIdType': invoice.receiverIdType,
        'concept': invoice.concept,
        'vatRate': invoice.vatRate,
        'currency': invoice.currency,
        'direction': direction,
        'taxLines':
            taxLines
                .map(
                  (t) => {
                    'rate': t.rate,
                    'base': t.base,
                    'quota': t.quota,
                    if (t.recargoEquivalencia != null)
                      'recargoEquivalencia': t.recargoEquivalencia,
                  },
                )
                .toList(),
        'reverseCharge':
            invoice.reverseCharge ??
            (doc.data()!['reverseCharge'] as bool? ?? false),
        'exemptionType': invoice.exemptionType ?? doc.data()!['exemptionType'],
        'specialRegime': invoice.specialRegime ?? doc.data()!['specialRegime'],
        'imageUrl': imageUrl,
      });
    } catch (e) {
      throw Exception("Error al actualizar la factura: $e");
    }
  }

  Future<String> _uploadImage(File file, String folder) async {
    final ext = _resolveExtension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final ref = storage.ref().child('$folder/$fileName');
    final metadata = SettableMetadata(
      contentType: _contentTypeForExtension(ext),
    );
    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  String _resolveExtension(String path) {
    final normalised = path.replaceAll('\\', '/');
    final name = normalised.split('/').last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < name.length - 1) {
      return name.substring(dotIndex).toLowerCase();
    }
    return '.bin';
  }

  String _contentTypeForExtension(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.jp2':
      case '.jpf':
      case '.jpx':
        return 'image/jp2';
      case '.tif':
      case '.tiff':
        return 'image/tiff';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  // Obtener factura por ID de un usuario
  @override
  Future<Invoice?> getInvoiceById(String userId, String id) async {
    try {
      final doc =
          await firestore
              .collection('users')
              .doc(userId)
              .collection('invoices')
              .doc(id)
              .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return Invoice(
        id: doc.id,
        title: data['title'],
        date: (data['date'] as Timestamp).toDate(),
        operationDate:
            (data['operationDate'] is Timestamp)
                ? (data['operationDate'] as Timestamp).toDate()
                : null,
        netAmount: (data['netAmount'] ?? 0).toDouble(),
        iva: (data['iva'] ?? 0).toDouble(),
        status: _parseStatus(data['status']),
        invoiceNumber: data['invoiceNumber'],
        series: data['series'],
        sequentialNumber:
            (data['sequentialNumber'] is int)
                ? data['sequentialNumber'] as int
                : (data['sequentialNumber'] is num)
                ? (data['sequentialNumber'] as num).toInt()
                : null,
        issuer: data['issuer'],
        issuerTaxId: data['issuerTaxId'],
        issuerAddress: data['issuerAddress'],
        issuerCountryCode: data['issuerCountryCode'],
        issuerIdType: data['issuerIdType'],
        receiver: data['receiver'],
        receiverTaxId: data['receiverTaxId'],
        receiverAddress: data['receiverAddress'],
        receiverCountryCode: data['receiverCountryCode'],
        receiverIdType: data['receiverIdType'],
        concept: data['concept'],
        vatRate: _parseNullableDouble(data['vatRate']),
        currency: (data['currency'] as String?) ?? 'EUR',
        direction: data['direction'] as String?,
        taxLines: _parseTaxLines(data['taxLines']),
        reverseCharge: data['reverseCharge'] as bool?,
        exemptionType: data['exemptionType'] as String?,
        specialRegime: data['specialRegime'] as String?,
        imageUrl: data['imageUrl'],
      );
    } catch (e) {
      throw Exception("Error al obtener la factura por ID: $e");
    }
  }

  double? _parseNullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  List<TaxLine>? _parseTaxLines(Object? raw) {
    if (raw is List) {
      final out = <TaxLine>[];
      for (final e in raw) {
        if (e is Map && e.containsKey('base') && e.containsKey('quota')) {
          final rate = (e['rate'] is num) ? (e['rate'] as num).toDouble() : 0.0;
          final base = (e['base'] as num).toDouble();
          final quota = (e['quota'] as num).toDouble();
          final rec =
              (e['recargoEquivalencia'] is num)
                  ? (e['recargoEquivalencia'] as num).toDouble()
                  : null;
          out.add(
            TaxLine(
              rate: rate,
              base: base,
              quota: quota,
              recargoEquivalencia: rec,
            ),
          );
        }
      }
      return out.isEmpty ? null : out;
    }
    return null;
  }

  List<TaxLine> _deriveSingleTaxLine(Invoice invoice) {
    final double base =
        (invoice.netAmount).clamp(0, double.infinity).toDouble();
    final double quota = (invoice.iva).clamp(0, double.infinity).toDouble();
    double rate;
    if (invoice.vatRate != null && invoice.vatRate! > 0) {
      rate = invoice.vatRate!;
    } else {
      rate = base > 0 ? (quota / base) : 0.0;
    }
    return [TaxLine(rate: rate, base: base, quota: quota)];
  }

  @visibleForTesting
  Future<({String series, int sequentialNumber, int year})>
  ensureIssuedInvoiceNumbering(
    String userId,
    Invoice invoice, {
    String? initialSeries,
  }) async {
    final year = (invoice.operationDate ?? invoice.date).year;
    final resolvedSeries =
        initialSeries ?? await resolveDefaultSeries(userId, year);
    final resolvedSequential = await allocateSequentialNumber(
      userId,
      resolvedSeries,
      year,
    );
    return (
      series: resolvedSeries,
      sequentialNumber: resolvedSequential,
      year: year,
    );
  }

  @protected
  Future<String> resolveDefaultSeries(String userId, int year) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      final data = userDoc.data() ?? {};
      final series = (data['defaultInvoiceSeries'] as String?) ?? 'A';
      return series;
    } catch (_) {
      return 'A';
    }
  }

  @protected
  Future<int> allocateSequentialNumber(
    String userId,
    String series,
    int year,
  ) async {
    final counterRef = firestore
        .collection('users')
        .doc(userId)
        .collection('invoice_counters')
        .doc('$series-$year');
    return await firestore.runTransaction<int>((tx) async {
      final snap = await tx.get(counterRef);
      int next;
      if (snap.exists) {
        final last = (snap.data()!['last'] as num?)?.toInt() ?? 0;
        next = last + 1;
      } else {
        next = 1;
      }
      tx.set(counterRef, {
        'series': series,
        'year': year,
        'last': next,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return next;
    });
  }

  InvoiceStatus _parseStatus(String? status) {
    switch (status) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'pending':
        return InvoiceStatus.pending;
      case 'sent':
        return InvoiceStatus.sent;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'paidByMe':
        return InvoiceStatus.paidByMe;
      default:
        return InvoiceStatus.pending;
    }
  }
}
