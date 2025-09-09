class BankTransaction {
  final String? id;
  final String description;
  final DateTime date;
  final double amount;
  final String? incomeId;

  const BankTransaction({
    this.id,
    required this.description,
    required this.date,
    required this.amount,
    this.incomeId,
  });

  BankTransaction copyWith({String? incomeId}) => BankTransaction(
    id: id,
    description: description,
    date: date,
    amount: amount,
    incomeId: incomeId ?? this.incomeId,
  );
}
