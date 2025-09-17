import 'dart:convert';
import 'dart:typed_data';

/// Utility to build minimalist PDF/A-1b compliant sample documents.
///
/// The implementation mirrors the manual generator used by
/// `tool/generate_sample_pdfs.dart` so the same PDF structure is available in
/// the Flutter application. Only a limited character set is supported; use
/// [sanitizeLine] to normalize arbitrary user input into a compatible form.
class PdfaGenerator {
  const PdfaGenerator._();

  /// Generates a PDF document using the provided [lines].
  static Uint8List generate({
    required String title,
    required String author,
    required String docId,
    required List<String> lines,
  }) {
    final sanitizedLines =
        lines.map(sanitizeLine).where((line) => line.isNotEmpty).toList();
    _ensurePatternsFor(sanitizedLines);

    final builder = _PdfBuilder();

    final literalTitle = _escapeLiteral(title);
    final literalAuthor = _escapeLiteral(author);
    final infoId = builder.addObject(
      '<< /Title ($literalTitle) /Author ($literalAuthor) '
      '/Producer (Gestr PDF/A sample generator) '
      '/CreationDate (D:20240101000000Z) /ModDate (D:20240101000000Z) >>',
    );

    final contentString = _buildContentStream(sanitizedLines);
    final contentBytes = ascii.encode(contentString);
    final contentId = builder.addStream(
      '<< /Length ${contentBytes.length} >>',
      contentBytes,
    );

    final colorSpaceId = builder.addObject(
      '[ /CalRGB << /WhitePoint [0.9505 1.0 1.0890] /Gamma [2.2 2.2 2.2] >> ]',
    );
    final resourcesId = builder.addObject(
      '<< /ColorSpace << /CS0 $colorSpaceId 0 R >> >>',
    );
    final pageId = builder.addObject(
      '<< /Type /Page /Parent 0 0 R /MediaBox [0 0 595 842] '
      '/Resources $resourcesId 0 R /Contents $contentId 0 R >>',
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
    return builder.build(
      rootId: catalogId,
      infoId: infoId,
      fileIdHex: fileIdHex,
    );
  }

  /// Normalizes an arbitrary [text] so it only includes characters supported by
  /// the sample glyph set.
  static String sanitizeLine(String text) {
    var normalized = text.toUpperCase();

    _simpleReplacements.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    final buffer = StringBuffer();
    for (final rune in normalized.runes) {
      final ch = String.fromCharCode(rune);
      if (_glyphPatterns.containsKey(ch)) {
        buffer.write(ch);
        continue;
      }
      final replacement = _fallbackCharacters[ch];
      if (replacement != null) {
        buffer.write(replacement);
        continue;
      }
      if (ch.trim().isEmpty) {
        buffer.write(' ');
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Generates a safe identifier for the PDF metadata.
  static String generateDocId(String seed) {
    final sanitized = sanitizeLine(seed).replaceAll(' ', '-');
    final fallback = sanitized.isEmpty ? 'GESTR-DOC' : sanitized;
    return fallback.length > 32 ? fallback.substring(0, 32) : fallback;
  }
}

String _buildContentStream(List<String> lines) {
  const startX = 72.0;
  const startY = 720.0;
  const cellSize = 2.0;
  const glyphColumns = 5;
  const glyphRows = 7;
  const glyphAdvance = glyphColumns * cellSize + cellSize;
  const leading = 18.0;

  final buffer =
      StringBuffer()
        ..writeln('q')
        ..writeln('/CS0 cs')
        ..writeln('0 0 0 sc');

  final rectangles = <String>[];

  for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    final line = lines[lineIndex];
    final topY = startY - lineIndex * leading;
    for (var charIndex = 0; charIndex < line.length; charIndex++) {
      final ch = line[charIndex];
      final pattern = _glyphPatterns[ch];
      if (pattern == null) {
        continue;
      }
      final baseX = startX + charIndex * glyphAdvance;
      for (var row = 0; row < glyphRows; row++) {
        final rowPattern = pattern[row];
        for (var col = 0; col < rowPattern.length; col++) {
          if (rowPattern[col] == '#') {
            final x = baseX + col * cellSize;
            final y = topY - (row + 1) * cellSize;
            rectangles.add(
              '${_formatNumber(x)} ${_formatNumber(y)} ${_formatNumber(cellSize)} ${_formatNumber(cellSize)} re',
            );
          }
        }
      }
    }
  }

  if (rectangles.isNotEmpty) {
    buffer.writeln(rectangles.join('\n'));
    buffer.writeln('f');
  }

  buffer.writeln('Q');
  return buffer.toString();
}

String _formatNumber(double value) {
  const epsilon = 1e-6;
  if ((value - value.roundToDouble()).abs() < epsilon) {
    return value.round().toString();
  }
  var text = value.toStringAsFixed(3);
  while (text.contains('.') && (text.endsWith('0') || text.endsWith('.'))) {
    text = text.substring(0, text.length - 1);
  }
  return text;
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

const Map<String, String> _fallbackCharacters = {
  'Á': 'A',
  'À': 'A',
  'Â': 'A',
  'Ä': 'A',
  'É': 'E',
  'È': 'E',
  'Ê': 'E',
  'Ë': 'E',
  'Í': 'I',
  'Ì': 'I',
  'Î': 'I',
  'Ï': 'I',
  'Ó': 'O',
  'Ò': 'O',
  'Ô': 'O',
  'Ö': 'O',
  'Ú': 'U',
  'Ù': 'U',
  'Û': 'U',
  'Ü': 'U',
  'Ñ': 'N',
  'Ç': 'C',
  '&': 'AND',
  '+': ' PLUS ',
  '%': ' PCT ',
  '/': '-',
};

const Map<String, String> _simpleReplacements = {'€': ' EUR '};

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
