import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/monthly_summary.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MonthlySummary> summaries;
  final bool isArabic;

  const MonthlyBarChart({
    super.key,
    required this.summaries,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return Center(
        child: Text(
          isArabic ? 'لا توجد بيانات شهرية' : 'No monthly data',
          style: TextStyle(color: Colors.white.withAlpha(102)),
        ),
      );
    }

    final reversed = summaries.reversed.toList();
    final maxValue = reversed.fold<double>(0, (max, s) =>
      [max, s.totalIncome, s.totalExpense].reduce((a, b) => a > b ? a : b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'المقارنة الشهرية' : 'Monthly Comparison',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue * 1.2,
              minY: 0,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= reversed.length) {
                        return const SizedBox();
                      }
                      final months = [
                        'Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          months[reversed[index].month - 1],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withAlpha(102),
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: maxValue / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withAlpha(13),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: reversed.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: s.totalIncome,
                      color: Colors.greenAccent,
                      width: 8,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: s.totalExpense,
                      color: Colors.redAccent,
                      width: 8,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: Colors.greenAccent, label: isArabic ? 'دخل' : 'Income'),
            const SizedBox(width: 24),
            _Legend(color: Colors.redAccent, label: isArabic ? 'مصروفات' : 'Expenses'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(3),
        )),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(128))),
      ],
    );
  }
}
