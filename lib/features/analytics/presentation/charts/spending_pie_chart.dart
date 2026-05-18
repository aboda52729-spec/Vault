import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/category.dart';

class SpendingPieChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final bool isArabic;

  const SpendingPieChart({
    super.key,
    required this.categoryTotals,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final total = categoryTotals.values.fold<double>(0, (s, v) => s + v);
    if (total == 0) {
      return Center(
        child: Text(
          isArabic ? 'لا توجد بيانات' : 'No data available',
          style: TextStyle(color: Colors.white.withAlpha(102)),
        ),
      );
    }

    final sections = categoryTotals.entries.map((entry) {
      final cat = TransactionCategory.fromId(entry.key);
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: percentage,
        color: Color(cat.colorValue),
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 50,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'توزيع المصروفات' : 'Spending Distribution',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 50,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: categoryTotals.entries.map((entry) {
            final cat = TransactionCategory.fromId(entry.key);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Color(cat.colorValue).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(cat.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.localizedName(isArabic),
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(cat.colorValue),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
