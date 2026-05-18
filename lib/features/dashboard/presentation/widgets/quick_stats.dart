import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/transaction.dart';

class QuickStats extends StatelessWidget {
  final List<BankakTransaction> transactions;
  final bool isArabic;

  const QuickStats({
    super.key,
    required this.transactions,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final thisMonth = transactions.where((t) {
      final now = DateTime.now();
      return t.date.month == now.month && t.date.year == now.year;
    }).toList();

    final income = thisMonth
        .where((t) => !t.isDebit)
        .fold<double>(0, (s, t) => s + t.amount);

    final expense = thisMonth
        .where((t) => t.isDebit)
        .fold<double>(0, (s, t) => s + t.amount);

    return Row(
      children: [
        _StatCard(
          icon: Icons.arrow_upward_rounded,
          label: isArabic ? 'وارد' : 'Income',
          amount: income,
          color: Colors.greenAccent,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.arrow_downward_rounded,
          label: isArabic ? 'منصرف' : 'Expenses',
          amount: expense,
          color: Colors.redAccent,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.receipt_long_rounded,
          label: isArabic ? 'حركات' : 'Transactions',
          amount: thisMonth.length.toDouble(),
          color: Colors.blueAccent,
          isCount: true,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final bool isCount;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(8)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              isCount ? amount.toInt().toString() : AppFormatters.formatAmount(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(102)),
            ),
          ],
        ),
      ),
    );
  }
}
