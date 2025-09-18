/// Helpers for formatting and normalizing timestamps for PDF metadata.
DateTime normalizeToSecondPrecisionUtc(DateTime timestamp) {
  final utc = timestamp.toUtc();
  return DateTime.utc(
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
  );
}

String formatIso8601Utc(DateTime timestamp) {
  final normalized = normalizeToSecondPrecisionUtc(timestamp);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  final hour = normalized.hour.toString().padLeft(2, '0');
  final minute = normalized.minute.toString().padLeft(2, '0');
  final second = normalized.second.toString().padLeft(2, '0');
  return '$year-$month-${day}T$hour:$minute:${second}Z';
}

String formatPdfDate(DateTime timestamp) {
  final normalized = normalizeToSecondPrecisionUtc(timestamp);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  final hour = normalized.hour.toString().padLeft(2, '0');
  final minute = normalized.minute.toString().padLeft(2, '0');
  final second = normalized.second.toString().padLeft(2, '0');
  return 'D:$year$month$day$hour$minute${second}Z';
}
