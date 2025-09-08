class TaxSummary {
  final double totalIncome;
  final double totalExpenses;
  final double vatCollected;
  final double vatPaid;
  final int invoiceCount;
  final double averageTicket;

  const TaxSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.vatCollected,
    required this.vatPaid,
    this.invoiceCount = 0,
    this.averageTicket = 0,
  });
}
