import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestr/data/repositories/invoice/invoice_repoditory_impl.dart';
import 'package:gestr/domain/entities/invoice_model.dart';

class _DummyFirebaseFirestore implements FirebaseFirestore {
  const _DummyFirebaseFirestore();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyFirebaseStorage implements FirebaseStorage {
  const _DummyFirebaseStorage();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestableInvoiceRepositoryImpl extends InvoiceRepositoryImpl {
  _TestableInvoiceRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required this.seriesToReturn,
    required this.sequentialToReturn,
  }) : super(firestore, storage: storage);

  final String seriesToReturn;
  final int sequentialToReturn;

  int? capturedSeriesYear;
  int? capturedSequentialYear;

  @override
  Future<String> resolveDefaultSeries(String userId, int year) async {
    capturedSeriesYear = year;
    return seriesToReturn;
  }

  @override
  Future<int> allocateSequentialNumber(
    String userId,
    String series,
    int year,
  ) async {
    capturedSequentialYear = year;
    return sequentialToReturn;
  }
}

void main() {
  const userId = 'user-123';
  const dummyFirestore = _DummyFirebaseFirestore();
  const dummyStorage = _DummyFirebaseStorage();

  Invoice buildInvoice({required DateTime date, DateTime? operationDate}) {
    return Invoice(
      title: 'Test invoice',
      date: date,
      operationDate: operationDate,
      netAmount: 100,
      iva: 21,
      status: InvoiceStatus.pending,
    );
  }

  test(
    'ensureIssuedInvoiceNumbering uses invoice date year when operation date is absent',
    () async {
      final repository = _TestableInvoiceRepositoryImpl(
        firestore: dummyFirestore,
        storage: dummyStorage,
        seriesToReturn: 'A',
        sequentialToReturn: 7,
      );

      final invoice = buildInvoice(date: DateTime(2021, 5, 12));

      final numbering = await repository.ensureIssuedInvoiceNumbering(
        userId,
        invoice,
        initialSeries: invoice.series,
      );

      expect(numbering.year, 2021);
      expect(numbering.series, 'A');
      expect(numbering.sequentialNumber, 7);
      final identifier =
          '${numbering.series}-${numbering.year}-${numbering.sequentialNumber.toString().padLeft(3, '0')}';
      expect(identifier, 'A-2021-007');
      expect(repository.capturedSeriesYear, 2021);
      expect(repository.capturedSequentialYear, 2021);
    },
  );

  test(
    'ensureIssuedInvoiceNumbering prioritizes operation date year when available',
    () async {
      final repository = _TestableInvoiceRepositoryImpl(
        firestore: dummyFirestore,
        storage: dummyStorage,
        seriesToReturn: 'B',
        sequentialToReturn: 3,
      );

      final invoice = buildInvoice(
        date: DateTime(2024, 1, 10),
        operationDate: DateTime(2022, 12, 31),
      );

      final numbering = await repository.ensureIssuedInvoiceNumbering(
        userId,
        invoice,
        initialSeries: invoice.series,
      );

      expect(numbering.year, 2022);
      expect(numbering.series, 'B');
      expect(numbering.sequentialNumber, 3);
      final identifier =
          '${numbering.series}-${numbering.year}-${numbering.sequentialNumber.toString().padLeft(3, '0')}';
      expect(identifier, 'B-2022-003');
      expect(repository.capturedSeriesYear, 2022);
      expect(repository.capturedSequentialYear, 2022);
    },
  );
}
