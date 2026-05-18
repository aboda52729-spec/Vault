import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import 'charts/spending_pie_chart.dart';
import 'charts/monthly_bar_chart.dart';
import 'charts/balance_line_chart.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/presentation/widgets/quick_stats.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final dashState = ref.watch(dashboardProvider);
    final isAr = state.isArabic;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isAr ? 'التحليلات' : 'Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuickStats(
              transactions: dashState.transactions,
              isArabic: isAr,
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(8)),
              ),
              child: SpendingPieChart(
                categoryTotals: state.categoryTotals,
                isArabic: isAr,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(8)),
              ),
              child: BalanceLineChart(
                transactions: dashState.transactions,
                isArabic: isAr,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(8)),
              ),
              child: MonthlyBarChart(
                summaries: state.monthlySummaries,
                isArabic: isAr,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
