import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/balance_card.dart';
import 'widgets/sync_panel.dart';
import 'widgets/transaction_item.dart';
import 'widgets/quick_stats.dart';

class MainDashboard extends ConsumerWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);
    final isAr = state.isArabic;

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () => notifier.syncWithSMS(),
        color: Theme.of(context).colorScheme.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: Colors.transparent,
              title: Text(
                isAr ? 'الخزنة' : 'Vault',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.translate_rounded),
                  onPressed: () => notifier.toggleLanguage(),
                  tooltip: isAr ? 'English' : 'العربية',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => notifier.clearAll(),
                  tooltip: isAr ? 'مسح الكل' : 'Clear All',
                ),
                IconButton(
                  icon: const Icon(Icons.pie_chart_rounded),
                  onPressed: () => context.push('/analytics'),
                  tooltip: isAr ? 'تحليلات' : 'Analytics',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BalanceCard(
                      balance: state.balance,
                      isArabic: isAr,
                    ),
                    const SizedBox(height: 24),
                    QuickStats(
                      transactions: state.transactions,
                      isArabic: isAr,
                    ),
                    const SizedBox(height: 30),
                    _SectionHeader(
                      title: isAr ? 'مزامنة حقيقية' : 'Real Sync',
                      subtitle: isAr ? 'اسحب بياناتك مباشرة من الرسائل' : 'Fetch data directly from SMS',
                    ),
                    const SizedBox(height: 15),
                    SyncPanel(
                      isArabic: isAr,
                      isSyncing: state.isSyncing,
                      errorMessage: state.errorMessage,
                      onSync: () => notifier.syncWithSMS(),
                    ),
                    const SizedBox(height: 30),
                    _SectionHeader(
                      title: isAr ? 'آخر الحركات' : 'Latest Transactions',
                      subtitle: '${state.transactions.length} ${isAr ? 'حركة' : 'transactions'}',
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (state.transactions.isEmpty && !state.isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: Colors.white.withAlpha(51)),
                      const SizedBox(height: 12),
                      Text(
                        isAr ? 'لا توجد بيانات، قم بالمزامنة' : 'No data, please sync',
                        style: TextStyle(color: Colors.white.withAlpha(102)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms),
              ),
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tx = state.transactions[index];
                  return TransactionItem(
                    tx: tx,
                    isArabic: isAr,
                    onTap: () => context.push('/transaction/${tx.id}'),
                    onDelete: () => notifier.deleteTransaction(tx.id),
                  );
                },
                childCount: state.transactions.length,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSetBalanceDialog(context, notifier, isAr),
        label: Text(isAr ? 'تعديل الرصيد' : 'Adjust Balance'),
        icon: const Icon(Icons.account_balance_wallet_rounded),
      ),
    );
  }

  void _showSetBalanceDialog(BuildContext context, DashboardNotifier notifier, bool isAr) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(isAr ? 'تعيين الرصيد الحالي' : 'Set Current Balance'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0.00',
            suffixText: 'SDG',
            filled: true,
            fillColor: Colors.white.withAlpha(13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              notifier.setBalance(val);
              Navigator.pop(ctx);
            },
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(128)),
        ),
      ],
    );
  }
}
