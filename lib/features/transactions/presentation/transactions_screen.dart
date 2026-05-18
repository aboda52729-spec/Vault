import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/transaction_provider.dart';
import '../../dashboard/presentation/widgets/transaction_item.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'widgets/filter_bar.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);
    final dashNotifier = ref.read(dashboardProvider.notifier);
    final isAr = state.isArabic;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isAr ? 'كل الحركات' : 'All Transactions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              onChanged: (v) => ref.read(transactionsProvider.notifier).setSearchQuery(v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isAr ? 'بحث...' : 'Search...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(77)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withAlpha(77)),
                filled: true,
                fillColor: Colors.white.withAlpha(13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          FilterBar(
            isArabic: isAr,
            selectedCategory: state.categoryFilter,
            onCategoryChanged: (c) =>
              ref.read(transactionsProvider.notifier).setCategoryFilter(c),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: Colors.white.withAlpha(51)),
                        const SizedBox(height: 12),
                        Text(
                          isAr ? 'لا توجد نتائج' : 'No results found',
                          style: TextStyle(color: Colors.white.withAlpha(102)),
                        ),
                      ],
                    ),
                  ).animate().fadeIn()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = state.filteredTransactions[index];
                      return TransactionItem(
                        tx: tx,
                        isArabic: isAr,
                        onTap: () => context.push('/transaction/${tx.id}'),
                        onDelete: () {
                          dashNotifier.deleteTransaction(tx.id);
                          ref.read(transactionsProvider.notifier).refresh();
                        },
                      ).animate().fadeIn(
                        duration: 300.ms,
                        delay: (index * 50).ms,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
