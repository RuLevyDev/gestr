import 'dart:convert';
import 'dart:typed_data';

class PdfaDocumentBuilder {
  final List<_PdfObject> _objects = [];
  int _nextId = 1;

  int addObject(String data) {
    final id = _nextId++;
    _objects.add(_PdfObject(id, ascii.encode(data)));
    return id;
  }

  int addStream(String dictionary, List<int> contentBytes) {
    final id = _nextId++;
    final buffer = BytesBuilder();
    buffer.add(ascii.encode('$dictionary\nstream\n'));
    buffer.add(contentBytes);
    buffer.add(ascii.encode('\nendstream'));
    _objects.add(_PdfObject(id, buffer.toBytes()));
    return id;
  }

  void replaceInObject(int id, String target, String replacement) {
    final obj = _objects.firstWhere((element) => element.id == id);
    final text = ascii.decode(obj.bytes);
    final updated = text.replaceFirst(target, replacement);
    obj.bytes = ascii.encode(updated);
  }

  Uint8List build({
    required int rootId,
    required int infoId,
    required String fileIdHex,
  }) {
    final header = latin1.encode('%PDF-1.4\n%\u00e2\u00e3\u00cf\u00d3\n');
    final buffer = BytesBuilder();
    buffer.add(header);

    final sorted = List<_PdfObject>.from(_objects)
      ..sort((a, b) => a.id.compareTo(b.id));

    final offsets = <int>[0];
    var currentOffset = header.length;

    for (final obj in sorted) {
      final objHeader = ascii.encode('${obj.id} 0 obj\n');
      final objFooter = ascii.encode('\nendobj\n');
      buffer.add(objHeader);
      buffer.add(obj.bytes);
      buffer.add(objFooter);
      offsets.add(currentOffset);
      currentOffset += objHeader.length + obj.bytes.length + objFooter.length;
    }

    final xrefOffset = currentOffset;
    final xref =
        StringBuffer()
          ..writeln('xref')
          ..writeln('0 ${offsets.length}')
          ..writeln('0000000000 65535 f ');

    for (var i = 1; i < offsets.length; i++) {
      xref.writeln('${offsets[i].toString().padLeft(10, '0')} 00000 n ');
    }

    xref
      ..writeln('trailer')
      ..writeln(
        '<< /Size ${offsets.length} /Root $rootId 0 R /Info $infoId 0 R /ID [<$fileIdHex> <$fileIdHex>] >>',
      )
      ..writeln('startxref')
      ..writeln('$xrefOffset')
      ..write('%%EOF\n');

    buffer.add(ascii.encode(xref.toString()));
    return buffer.toBytes();
  }
}

class _PdfObject {
  _PdfObject(this.id, this.bytes);

  final int id;
  List<int> bytes;
}
