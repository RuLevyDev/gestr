class Income {
  final String? id;
  final String title;
  final DateTime date;
  final double amount;
  final String? source;

  const Income({
    this.id,
    required this.title,
    required this.date,
    required this.amount,
    this.source,
  });
}

