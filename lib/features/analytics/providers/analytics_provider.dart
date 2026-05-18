import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/monthly_summary.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final analyticsProvider = Provider<AnalyticsState>((ref) {
  final txRepo = ref.watch(transactionRepositoryProvider);
  final dashState = ref.watch(dashboardProvider);

  final allTransactions = txRepo.getAll();
  final categoryTotals = txRepo.categoryTotals;
  final monthlySummaries = txRepo.getMonthlySummaries(months: 12);

  return AnalyticsState(
    totalTransactions: allTransactions.length,
    categoryTotals: categoryTotals,
    monthlySummaries: monthlySummaries,
    isArabic: dashState.isArabic,
  );
});

class AnalyticsState {
  final int totalTransactions;
  final Map<String, double> categoryTotals;
  final List<MonthlySummary> monthlySummaries;
  final bool isArabic;

  AnalyticsState({
    required this.totalTransactions,
    required this.categoryTotals,
    required this.monthlySummaries,
    required this.isArabic,
  });

  double get totalExpense =>
      categoryTotals.values.fold<double>(0, (s, v) => s + v);

  double get totalIncome =>
      monthlySummaries.fold<double>(0, (s, m) => s + m.totalIncome);
}
