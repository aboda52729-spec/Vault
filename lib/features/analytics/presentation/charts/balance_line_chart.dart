import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/transaction.dart';

class BalanceLineChart extends StatelessWidget {
  final List<BankakTransaction> transactions;
  final bool isArabic;

  const BalanceLineChart({
    super.key,
    required this.transactions,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          isArabic ? 'لا توجد بيانات' : 'No data available',
          style: TextStyle(color: Colors.white.withAlpha(102)),
        ),
      );
    }

    final sorted = List<BankakTransaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = sorted.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.balanceAfter);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'تطور الرصيد' : 'Balance History',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              minY: minY - padding,
              maxY: maxY + padding,
              gridData: FlGridData(
                show: true,
                horizontalInterval: range / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withAlpha(13),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.white.withAlpha(8),
                  strokeWidth: 0,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: spots.length > 6 ? (spots.length / 5).ceilToDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= sorted.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${sorted[index].date.month}/${sorted[index].date.day}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withAlpha(77),
                          ),
                        ),
                      );
                    },
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
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: spots.length < 30,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withAlpha(51),
                        Theme.of(context).colorScheme.primary.withAlpha(8),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) {
                    return LineTooltipItem(
                      '${spot.y.toStringAsFixed(2)} SDG',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
