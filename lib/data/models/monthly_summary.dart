class MonthlySummary {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double netChange;
  final double startingBalance;
  final double endingBalance;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.startingBalance,
    required this.endingBalance,
  }) : netChange = totalIncome - totalExpense;
}
