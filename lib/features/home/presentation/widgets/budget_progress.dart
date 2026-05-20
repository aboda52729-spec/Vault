import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../features/budget/models/budget.dart';
import '../../../../data/models/category.dart';
import '../../../../core/utils/formatters.dart';

class BudgetProgressCard extends StatelessWidget {
  final BudgetEntry budget;
  final double spent;
  final bool isArabic;

  const BudgetProgressCard({
    super.key,
    required this.budget,
    required this.spent,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final category = TransactionCategory.fromId(budget.category);
    final percentage = (budget.amount > 0) ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;
    final remaining = budget.amount - spent;
    final isOver = remaining < 0;

    final color = isOver ? Colors.red : Color(category.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    IconData(int.parse(category.iconName == 'receipt_long' ? '0xe5cb' : category.iconName), fontFamily: 'MaterialIcons'),
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.localizedName(isArabic),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatCurrency(spent),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                isArabic
                    ? '${formatCurrency(budget.amount)} /'
                    : '/ ${formatCurrency(budget.amount)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          if (isOver) ...[
            const SizedBox(height: 8),
            Text(
              isArabic ? '⚠️ تجاوزت الميزانية!' : '⚠️ Budget exceeded!',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ).animate().shimmer(duration: 1.5.s),
          ],
        ],
      ),
    );
  }
}
