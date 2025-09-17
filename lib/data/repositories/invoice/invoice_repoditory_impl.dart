import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestr/domain/entities/invoice_model.dart';
import 'package:gestr/domain/repositories/invoice/invoice_reposiroty.dart';
import 'package:firebase_storage/firebase_storage.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  InvoiceRepositoryImpl(this.firestore) : storage = FirebaseStorage.instance;

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
            netAmount: (data['netAmount'] ?? 0).toDouble(),
            iva: (data['iva'] ?? 0).toDouble(),
            status: status,
            issuer: data['issuer'],
            receiver: data['receiver'],
            concept: data['concept'],
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

      await firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .add({
            'title': invoice.title,
            'date': invoice.date,
            'netAmount': invoice.netAmount,
            'iva': invoice.iva,
            'status': invoice.status.name,
            'issuer': invoice.issuer,
            'receiver': invoice.receiver,
            'concept': invoice.concept,
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

      await docRef.update({
        'title': invoice.title,
        'date': invoice.date,
        'netAmount': invoice.netAmount,
        'iva': invoice.iva,
        'status': invoice.status.name,
        'issuer': invoice.issuer,
        'receiver': invoice.receiver,
        'concept': invoice.concept,
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
        netAmount: (data['netAmount'] ?? 0).toDouble(),
        iva: (data['iva'] ?? 0).toDouble(),
        status: _parseStatus(data['status']),
        issuer: data['issuer'],
        receiver: data['receiver'],
        concept: data['concept'],
        imageUrl: data['imageUrl'],
      );
    } catch (e) {
      throw Exception("Error al obtener la factura por ID: $e");
    }
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
