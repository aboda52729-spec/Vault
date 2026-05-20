import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/services/sms_service.dart';
import '../../../data/services/sms_parser_service.dart';
import '../../../core/utils/formatters.dart';
import '../presentation/widgets/glass_card.dart';
import '../presentation/widgets/budget_progress.dart';
import '../presentation/widgets/recent_transactions.dart';
import '../../settings/providers/settings_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../budget/providers/budget_provider.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final _smsService = SmsService();
  bool _isSyncing = false;
  String _syncMessage = '';
  final _scrollController = ScrollController();
  final _budgetRepo = BudgetRepository();

  @override
  void initState() {
    super.initState();
    _budgetRepo.init().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _syncSms() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = '';
    });

    try {
      final isArabic = ref.read(settingsStateProvider).isArabic;
      final result = await _smsService.getBankakMessages();
      if (result.isEmpty) {
        setState(() {
          _syncMessage = isArabic ? 'لم يتم العثور على رسائل جديدة' : 'No new messages found';
          _isSyncing = false;
        });
        return;
      }

      final txRepo = ref.read(transactionRepositoryProvider);
      int synced = 0;

      for (final sms in result) {
        final parsed = SmsParserService.parse(sms.body, isArabic: isArabic);
        if (parsed.amount > 0) {
          final tx = SmsParserService.toTransaction(
            parsed,
            id: sms.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            date: sms.date,
            currentBalance: dashboard.balance,
          );
          await txRepo.add(tx);
          synced++;
        }
      }

      if (synced == 0) {
        setState(() {
          _syncMessage = isArabic ? 'جميع الرسائل موجودة بالفعل' : 'All messages already synced';
        });
      } else {
        ref.invalidate(dashboardProvider);
        ref.invalidate(budgetProvider);
        setState(() {
          _syncMessage = isArabic ? 'تم استيراد $synced عملية بنجاح ✓' : 'Successfully imported $synced transactions ✓';
        });
      }
    } catch (e) {
      setState(() {
        _syncMessage = 'خطأ في المزامنة: $e';
      });
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(settingsStateProvider).isArabic;
    final dashboard = ref.watch(dashboardProvider);
    final budgets = ref.watch(budgetProvider);

    final now = DateTime.now();
    final currentBudgets = _budgetRepo.getBudgets(now.month, now.year);
    final categoryTotals = ref.watch(transactionRepositoryProvider).categoryTotals;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar.large(
          title: Text(isArabic ? '🏠 الرئيسية' : '🏠 Home'),
          actions: [
            IconButton(
              icon: Icon(_isSyncing ? Icons.sync : Icons.sync_alt),
              onPressed: _isSyncing ? null : _syncSms,
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      Text(
                        isArabic ? 'الرصيد المتاح' : 'Available Balance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatCurrency(dashboard.balance),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _quickStat(
                            isArabic ? 'الدخل' : 'Income',
                            formatCurrency(dashboard.monthlyIncome),
                            Icons.arrow_downward,
                            Colors.green,
                          ),
                          _quickStat(
                            isArabic ? 'المصروف' : 'Expenses',
                            formatCurrency(dashboard.monthlyExpense),
                            Icons.arrow_upward,
                            Colors.red,
                          ),
                          _quickStat(
                            isArabic ? 'العمليات' : 'Transactions',
                            '${dashboard.transactions.length}',
                            Icons.receipt_long,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_syncMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _syncMessage.contains('✓')
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _syncMessage.contains('✓')
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Text(_syncMessage),
                  ).animate().slideY(begin: -0.2, end: 0).fadeIn(),

                if (currentBudgets.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? '📊 الميزانيات الشهرية' : '📊 Monthly Budgets',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...currentBudgets.map((budget) {
                    final spent = categoryTotals[budget.category] ?? 0;
                    return BudgetProgressCard(
                      budget: budget,
                      spent: spent,
                      isArabic: isArabic,
                    ).animate().fadeIn().slideX();
                  }),
                ],

                const SizedBox(height: 24),
                Text(
                  isArabic ? '📋 آخر العمليات' : '📋 Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                RecentTransactionsList(isArabic: isArabic),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
