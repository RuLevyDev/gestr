import 'dart:collection';

/// Shared pixel-based font used for manual PDF/A generation.
///
/// The glyphs are rendered on a 5x7 grid and scaled according to the
/// requested font size. This mirrors the implementation originally embedded in
/// `pdfa_generator.dart` but is now reusable so other generators can rely on
/// the exact same alphabet and sanitising rules.
class PixelFont {
  PixelFont._();

  static const double _cellSize = 2.0;
  static const int _glyphColumns = 5;
  static const int _glyphRows = 7;
  static const double _glyphAdvance = _glyphColumns * _cellSize + _cellSize;
  static const double _baseFontSize = 12.0;
  static const double _baseLineHeight = 18.0;

  /// Sanitises arbitrary text so it only contains glyphs available in the
  /// pixel alphabet. Unsupported characters are stripped or replaced with
  /// sensible ASCII fallbacks.
  static String sanitize(String text) {
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

  /// Ensures that every line can be represented with the available glyphs.
  /// Throws if an unsupported character remains after sanitising.
  static void ensureCoverage(Iterable<String> lines) {
    final needed = SplayTreeSet<String>();
    for (final line in lines) {
      for (final rune in line.runes) {
        needed.add(String.fromCharCode(rune));
      }
    }

    final missing =
        needed.where((ch) => !_glyphPatterns.containsKey(ch)).toList();
    if (missing.isNotEmpty) {
      throw StateError('Missing glyph patterns for: ${missing.join(', ')}');
    }
  }

  /// Calculates the width of a string rendered at [fontSize]. The input should
  /// already be sanitised.
  static double measureWidth(String text, double fontSize) {
    if (text.isEmpty) return 0;
    return text.length * _glyphAdvance * _scaleFor(fontSize);
  }

  /// Returns the default line height for the provided [fontSize].
  static double lineHeight(double fontSize) {
    return _baseLineHeight * _scaleFor(fontSize);
  }

  /// Returns the rectangles needed to render a single sanitised line.
  ///
  /// The [topY] coordinate represents the top of the bounding box in PDF space
  /// (i.e. with the origin at the bottom-left of the page). The caller is
  /// responsible for ensuring the input has already been sanitised.
  static Iterable<PixelGlyphRect> buildLineRects(
    String sanitisedLine, {
    required double left,
    required double topY,
    required double fontSize,
  }) sync* {
    if (sanitisedLine.isEmpty) return;

    final scale = _scaleFor(fontSize);
    final cell = _cellSize * scale;
    final glyphAdvance = _glyphAdvance * scale;

    for (var charIndex = 0; charIndex < sanitisedLine.length; charIndex++) {
      final pattern = _glyphPatterns[sanitisedLine[charIndex]];
      if (pattern == null) continue;

      final baseX = left + charIndex * glyphAdvance;
      for (var row = 0; row < pattern.length; row++) {
        final rowPattern = pattern[row];
        for (var col = 0; col < rowPattern.length; col++) {
          if (rowPattern[col] != '#') continue;
          final x = baseX + col * cell;
          final y = topY - (row + 1) * cell;
          yield PixelGlyphRect(x, y, cell, cell);
        }
      }
    }
  }

  /// Wraps [text] so each sanitised line fits within [maxWidth].
  static List<String> wrap(
    String text, {
    required double fontSize,
    required double maxWidth,
  }) {
    final sanitised = sanitize(text);
    if (sanitised.isEmpty) {
      return <String>[];
    }

    final scale = _scaleFor(fontSize);
    final glyphWidth = _glyphAdvance * scale;
    if (maxWidth <= glyphWidth) {
      return _splitChunks(sanitised, 1);
    }

    final maxCharsPerLine = maxWidth ~/ glyphWidth;
    if (maxCharsPerLine <= 0) {
      return _splitChunks(sanitised, 1);
    }

    final lines = <String>[];
    var current = StringBuffer();

    void flushCurrent() {
      if (current.isNotEmpty) {
        lines.add(current.toString().trim());
        current = StringBuffer();
      }
    }

    final words = sanitised.split(' ');
    for (final word in words) {
      if (word.isEmpty) continue;
      if (word.length > maxCharsPerLine) {
        flushCurrent();
        lines.addAll(_splitChunks(word, maxCharsPerLine));
        continue;
      }
      final tentative = current.isEmpty ? word : '${current.toString()} $word';
      if (tentative.length <= maxCharsPerLine) {
        current
          ..clear()
          ..write(tentative);
      } else {
        flushCurrent();
        current.write(word);
      }
    }

    flushCurrent();
    return lines;
  }

  static List<String> _splitChunks(String value, int chunkLength) {
    if (value.isEmpty) return <String>[];
    final chunks = <String>[];
    for (var i = 0; i < value.length; i += chunkLength) {
      final end = (i + chunkLength).clamp(0, value.length);
      chunks.add(value.substring(i, end));
    }
    return chunks;
  }

  static double _scaleFor(double fontSize) => fontSize / _baseFontSize;
}

class PixelGlyphRect {
  const PixelGlyphRect(this.x, this.y, this.width, this.height);

  final double x;
  final double y;
  final double width;
  final double height;
}

Map<String, String> get _simpleReplacements => const {'€': ' EUR '};

Map<String, String> get _fallbackCharacters => const {
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

Map<String, List<String>> get _glyphPatterns => const {
  'A': ['..#..', '.#.#.', '#...#', '#####', '#...#', '#...#', '#...#'],
  'B': ['####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.'],
  'C': ['.####', '#....', '#....', '#....', '#....', '#....', '.####'],
  'D': ['####.', '#...#', '#...#', '#...#', '#...#', '#...#', '####.'],
  'E': ['#####', '#....', '#....', '####.', '#....', '#....', '#####'],
  'F': ['#####', '#....', '#....', '####.', '#....', '#....', '#....'],
  'G': ['.####', '#....', '#....', '#.###', '#...#', '#...#', '.###.'],
  'H': ['#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  'I': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '#####'],
  'J': ['..###', '...#.', '...#.', '...#.', '#..#.', '#..#.', '.##..'],
  'K': ['#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#'],
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
  'W': ['#...#', '#...#', '#.#.#', '#.#.#', '#.#.#', '##.##', '#...#'],
  'X': ['#...#', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '#...#'],
  'Y': ['#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..'],
  'Z': ['#####', '....#', '...#.', '..#..', '.#...', '#....', '#####'],
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
