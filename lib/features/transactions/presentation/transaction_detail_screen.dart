import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/category.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);
    final tx = state.transactions.where((t) => t.id == transactionId).firstOrNull;
    final isAr = state.isArabic;

    if (tx == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text(isAr ? 'خطأ' : 'Error')),
        body: Center(child: Text(isAr ? 'الحركة غير موجودة' : 'Transaction not found')),
      );
    }

    final category = TransactionCategory.fromId(tx.category);
    final isDebit = tx.isDebit;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isAr ? 'تفاصيل الحركة' : 'Transaction Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isDebit ? Colors.redAccent : Colors.greenAccent).withAlpha(25),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isDebit ? Icons.south_east_rounded : Icons.north_east_rounded,
                color: isDebit ? Colors.redAccent : Colors.greenAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppFormatters.formatWithSign(tx.amount, isDebit: isDebit),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w200,
                color: isDebit ? Colors.white : Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Color(category.colorValue).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category.localizedName(isAr),
                style: TextStyle(color: Color(category.colorValue)),
              ),
            ),
            const SizedBox(height: 40),
            _DetailRow(
              label: isAr ? 'الوصف' : 'Description',
              value: tx.description,
            ),
            _DetailRow(
              label: isAr ? 'التاريخ' : 'Date',
              value: AppFormatters.formatDate(tx.date),
            ),
            _DetailRow(
              label: isAr ? 'النوع' : 'Type',
              value: isDebit
                  ? (isAr ? 'خصم' : 'Debit')
                  : (isAr ? 'إيداع' : 'Credit'),
              valueColor: isDebit ? Colors.redAccent : Colors.greenAccent,
            ),
            _DetailRow(
              label: isAr ? 'الرصيد بعد العملية' : 'Balance After',
              value: '${AppFormatters.formatAmount(tx.balanceAfter)} SDG',
            ),
            _DetailRow(
              label: isAr ? 'التصنيف' : 'Category',
              value: category.localizedName(isAr),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
