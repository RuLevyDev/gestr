import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main(List<String> args) {
  final outputDir = Directory('samples/pdfs');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  stdout.writeln('Generating PDF/A sample documents in ${outputDir.path}');

  final descriptors = <_PdfDescriptor>[
    const _PdfDescriptor(
      fileName: 'fixed_payment_sample.pdf',
      title: 'Fixed Payment Sample',
      author: 'Gestr App',
      docId: 'uuid-fixed',
      lines: [
        'FIXED PAYMENT SUMMARY',
        'PLAN: ALPHA',
        'START DATE: 2024-01-15',
        'AMOUNT: EUR 39.90',
        'FREQUENCY: MONTHLY',
        'STATUS: ACTIVE',
      ],
    ),
    const _PdfDescriptor(
      fileName: 'invoice_sample.pdf',
      title: 'Invoice Sample',
      author: 'Gestr App',
      docId: 'uuid-invoice',
      lines: [
        'INVOICE SUMMARY',
        'CLIENT: ACME CORP',
        'ISSUE DATE: 2024-05-30',
        'TOTAL: EUR 1,512.50',
        'STATUS: PAID',
        'NOTES: SAMPLE RECORD',
      ],
    ),
  ];

  for (final descriptor in descriptors) {
    _ensurePatternsFor(descriptor.lines);
    final bytes = _buildPdf(
      title: descriptor.title,
      author: descriptor.author,
      lines: descriptor.lines,
      docId: descriptor.docId,
    );
    final file = File('${outputDir.path}/${descriptor.fileName}');
    file.writeAsBytesSync(bytes, flush: true);
  }

  stdout.writeln('Generated files:');

  for (final descriptor in descriptors) {
    final file = File('${outputDir.path}/${descriptor.fileName}');
    if (file.existsSync()) {
      stdout.writeln(' - ${file.path} (${file.lengthSync()} bytes)');
    }
  }
}

Uint8List _buildPdf({
  required String title,
  required String author,
  required List<String> lines,
  required String docId,
}) {
  final builder = _PdfBuilder();

  final literalTitle = _escapeLiteral(title);
  final literalAuthor = _escapeLiteral(author);
  final infoId = builder.addObject(
    '<< /Title ($literalTitle) /Author ($literalAuthor) /Producer (Gestr PDF/A sample generator) /CreationDate (D:20240101000000Z) /ModDate (D:20240101000000Z) >>',
  );

  final contentString = _buildContentStream(lines);
  final contentBytes = ascii.encode(contentString);
  final contentId = builder.addStream(
    '<< /Length ${contentBytes.length} >>',
    contentBytes,
  );

  final colorSpaceId = builder.addObject(
    '<< /Type /CalRGB /WhitePoint [0.9505 1.0 1.0890] /Gamma [2.2 2.2 2.2] >>',
  );
  final resourcesId = builder.addObject(
    '<< /ColorSpace << /CS0 $colorSpaceId 0 R >> >>',
  );

  final pageId = builder.addObject(
    '<< /Type /Page /Parent 0 0 R /MediaBox [0 0 595 842] /Resources $resourcesId 0 R /Contents $contentId 0 R >>',
  );

  final pagesId = builder.addObject(
    '<< /Type /Pages /Kids [$pageId 0 R] /Count 1 >>',
  );
  builder.replaceInObject(pageId, '/Parent 0 0 R', '/Parent $pagesId 0 R');

  final xmpString = _buildXmp(title: title, author: author, docId: docId);
  final xmpBytes = utf8.encode(xmpString);
  final metadataId = builder.addStream(
    '<< /Type /Metadata /Subtype /XML /Length ${xmpBytes.length} >>',
    xmpBytes,
  );

  final catalogId = builder.addObject(
    '<< /Type /Catalog /Pages $pagesId 0 R /Metadata $metadataId 0 R /Lang (en-US) >>',
  );

  final fileIdHex = _buildFileIdHex(docId);

  return builder.build(rootId: catalogId, infoId: infoId, fileIdHex: fileIdHex);
}

String _buildContentStream(List<String> lines) {
  const cellSize = 4;
  const glyphAdvance = cellSize * 6;
  const lineHeight = cellSize * 10;
  const startX = 72;
  const startY = 760;

  final buffer =
      StringBuffer()
        ..writeln('q')
        ..writeln('/CS0 cs')
        ..writeln('0 0 0 sc');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineTop = startY - i * lineHeight;
    for (var j = 0; j < line.length; j++) {
      final ch = line[j];
      if (ch == ' ') {
        continue;
      }
      final pattern = _glyphPatterns[ch];
      if (pattern == null) {
        throw StateError('Missing glyph pattern for "$ch"');
      }
      final rows = pattern.length;
      final glyphX = startX + j * glyphAdvance;
      final glyphTop = lineTop;

      for (var row = 0; row < rows; row++) {
        final patternRow = pattern[row];
        for (var col = 0; col < patternRow.length; col++) {
          if (patternRow[col] != '#') {
            continue;
          }
          final rectX = glyphX + col * cellSize;
          final rectY = glyphTop - (row + 1) * cellSize;
          buffer.writeln('$rectX $rectY $cellSize $cellSize re');
          buffer.writeln('f');
        }
      }
    }
  }

  buffer.writeln('Q');
  return buffer.toString();
}

class _PdfDescriptor {
  const _PdfDescriptor({
    required this.fileName,
    required this.title,
    required this.author,
    required this.docId,
    required this.lines,
  });

  final String fileName;
  final String title;
  final String author;
  final String docId;
  final List<String> lines;
}

class _PdfObject {
  _PdfObject(this.id, this.bytes);

  final int id;
  List<int> bytes;
}

class _PdfBuilder {
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

String _buildFileIdHex(String seed) {
  final source = seed.isEmpty ? 'gestr-doc-id' : seed;
  final bytes = List<int>.generate(16, (index) {
    final char = source.codeUnitAt(index % source.length);
    return (char + index) & 0xff;
  });

  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

String _escapeText(String text) {
  return text
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
}

String _escapeLiteral(String text) => _escapeText(text);

String _buildXmp({
  required String title,
  required String author,
  required String docId,
}) {
  final escapedTitle = const HtmlEscape().convert(title);
  final escapedAuthor = const HtmlEscape().convert(author);
  return '''<?xpacket begin='\ufeff' id='$docId'?>
<x:xmpmeta xmlns:x='adobe:ns:meta/'>
  <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
    <rdf:Description rdf:about='' xmlns:dc='http://purl.org/dc/elements/1.1/' xmlns:pdf='http://ns.adobe.com/pdf/1.3/' xmlns:xmp='http://ns.adobe.com/xap/1.0/' xmlns:pdfaid='http://www.aiim.org/pdfa/ns/id/'>
      <dc:title><rdf:Alt><rdf:li xml:lang='x-default'>$escapedTitle</rdf:li></rdf:Alt></dc:title>
      <dc:creator><rdf:Seq><rdf:li>$escapedAuthor</rdf:li></rdf:Seq></dc:creator>
      <pdf:Producer>Gestr PDF/A sample generator</pdf:Producer>
      <xmp:CreateDate>2024-01-01T00:00:00Z</xmp:CreateDate>
      <xmp:ModifyDate>2024-01-01T00:00:00Z</xmp:ModifyDate>
      <pdfaid:part>1</pdfaid:part>
      <pdfaid:conformance>B</pdfaid:conformance>
    </rdf:Description>
  </rdf:RDF>
</x:xmpmeta>
<?xpacket end='w'?>''';
}

void _ensurePatternsFor(List<String> lines) {
  final needed = <String>{};
  for (final line in lines) {
    needed.addAll(line.split(''));
  }
  final missing =
      needed.where((ch) => !_glyphPatterns.containsKey(ch)).toList()..sort();
  if (missing.isNotEmpty) {
    throw StateError('Missing glyph patterns for: ${missing.join(', ')}');
  }
}

const Map<String, List<String>> _glyphPatterns = {
  'A': ['..#..', '.#.#.', '#...#', '#####', '#...#', '#...#', '#...#'],
  'C': ['.####', '#....', '#....', '#....', '#....', '#....', '.####'],
  'D': ['####.', '#...#', '#...#', '#...#', '#...#', '#...#', '####.'],
  'E': ['#####', '#....', '#....', '####.', '#....', '#....', '#####'],
  'F': ['#####', '#....', '#....', '####.', '#....', '#....', '#....'],
  'G': ['.####', '#....', '#....', '#.###', '#...#', '#...#', '.###.'],
  'H': ['#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  'I': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '#####'],
  'L': ['#....', '#....', '#....', '#....', '#....', '#....', '#####'],
  'M': ['#...#', '##.##', '#.#.#', '#.#.#', '#...#', '#...#', '#...#'],
  'N': ['#...#', '##..#', '#.#.#', '#..##', '#...#', '#...#', '#...#'],
  'O': ['.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
  'P': ['####.', '#...#', '#...#', '####.', '#....', '#....', '#....'],
  'Q': ['.###.', '#...#', '#...#', '#...#', '#.#.#', '#..#.', '.##.#'],
  'R': ['####.', '#...#', '#...#', '####.', '#.#..', '#..#.', '#...#'],
  'S': ['.####', '#....', '#....', '.###.', '....#', '....#', '####.'],
  'T': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
  'U': ['#...#', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
  'V': ['#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..'],
  'X': ['#...#', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '#...#'],
  'Y': ['#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..'],
  '0': ['.###.', '#..##', '#.#.#', '#.#.#', '##..#', '#...#', '.###.'],
  '1': ['..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'],
  '2': ['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
  '3': ['#####', '....#', '...#.', '..##.', '....#', '#...#', '.###.'],
  '4': ['...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.'],
  '5': ['#####', '#....', '####.', '....#', '....#', '#...#', '.###.'],
  '6': ['.###.', '#....', '#....', '####.', '#...#', '#...#', '.###.'],
  '7': ['#####', '....#', '...#.', '..#..', '..#..', '..#..', '..#..'],
  '8': ['.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.'],
  '9': ['.###.', '#...#', '#...#', '.####', '....#', '....#', '.###.'],
  ':': ['..#..', '..#..', '.....', '.....', '..#..', '..#..', '.....'],
  '-': ['.....', '.....', '.....', '.###.', '.....', '.....', '.....'],
  ',': ['.....', '.....', '.....', '.....', '..#..', '.#...', '#....'],
  '.': ['.....', '.....', '.....', '.....', '.....', '..#..', '..#..'],
  ' ': ['.....', '.....', '.....', '.....', '.....', '.....', '.....'],
};
