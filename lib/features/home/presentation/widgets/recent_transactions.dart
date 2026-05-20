import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../core/utils/formatters.dart';

class RecentTransactionsList extends ConsumerWidget {
  final bool isArabic;

  const RecentTransactionsList({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txRepo = ref.watch(transactionRepositoryProvider);
    final recent = txRepo.recentTransactions.take(5).toList();

    if (recent.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                isArabic ? 'لا توجد عمليات بعد' : 'No transactions yet',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic ? 'اضغط زر المزامنة لاستيراد الرسائل' : 'Tap sync to import SMS messages',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recent.map((tx) {
        final category = tx.category;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.03),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(category.colorValue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Color(category.colorValue),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.localizedName(isArabic),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      formatDate(tx.date),
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatCurrency(tx.amount),
                style: TextStyle(
                  color: Color(category.colorValue),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
