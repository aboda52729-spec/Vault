import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/transaction.dart';

class TransactionItem extends StatelessWidget {
  final BankakTransaction tx;
  final bool isArabic;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionItem({
    super.key,
    required this.tx,
    required this.isArabic,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = tx.isDebit;
    final color = isDebit ? Colors.redAccent : Colors.greenAccent;
    final category = TransactionCategory.fromId(tx.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Dismissible(
        key: Key(tx.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(isArabic ? 'حذف الحركة؟' : 'Delete transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(isArabic ? 'حذف' : 'Delete'),
              ),
            ],
          ),
        ),
        onDismissed: (_) => onDelete?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.redAccent.withAlpha(40),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDebit
                        ? Colors.redAccent.withAlpha(25)
                        : Colors.greenAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isDebit
                        ? Icons.south_east_rounded
                        : Icons.north_east_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Color(category.colorValue).withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _iconFromName(category.iconName),
                                  size: 12,
                                  color: Color(category.colorValue),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category.localizedName(isArabic),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(category.colorValue),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppFormatters.formatDate(tx.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(77),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatWithSign(tx.amount, isDebit: isDebit),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDebit ? Colors.white : Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.formatAmount(tx.balanceAfter),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withAlpha(51),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'receipt_long': return Icons.receipt_long;
      case 'restaurant': return Icons.restaurant;
      case 'swap_horiz': return Icons.swap_horiz;
      case 'phone_android': return Icons.phone_android;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'shopping_bag': return Icons.shopping_bag;
      default: return Icons.more_horiz;
    }
  }
}
