import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../home/presentation/widgets/glass_card.dart';
import '../../settings/providers/settings_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../budget/providers/budget_provider.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _pinController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  bool _showPinSetup = false;
  bool _showBudgetSetup = false;

  @override
  void dispose() {
    _pinController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🗑️ مسح جميع البيانات'),
        content: const Text('هل أنت متأكد؟ سيتم حذف جميع العمليات والميزانيات بشكل نهائي.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final txRepo = ref.read(transactionRepositoryProvider);
      final budgetRepo = BudgetRepository();
      await budgetRepo.init();
      await txRepo.clearAll();
      await budgetRepo.clearAll();
      ref.invalidate(dashboardProvider);
      ref.invalidate(budgetProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم مسح جميع البيانات ✓')),
        );
      }
    }
  }

  Future<void> _setupPin(String pin) async {
    await ref.read(settingsStateProvider.notifier).setPin(pin);
    setState(() => _showPinSetup = false);
    ref.invalidate(settingsStateProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعيين PIN بنجاح ✓')),
      );
    }
  }

  Future<void> _removePin() async {
    await ref.read(settingsStateProvider.notifier).removePin();
    ref.invalidate(settingsStateProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إزالة PIN ✓')),
      );
    }
  }

  Future<void> _saveBudget(String category, double amount) async {
    final budgetRepo = BudgetRepository();
    await budgetRepo.init();
    final now = DateTime.now();
    await budgetRepo.setBudget(category, amount, now.month, now.year);
    ref.invalidate(budgetProvider);
    setState(() => _showBudgetSetup = false);
    _amountController.clear();
    _selectedCategory = null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الميزانية ✓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(settingsStateProvider).isArabic;
    final hasPin = ref.watch(settingsStateProvider).hasPin;
    final canBio = ref.watch(settingsStateProvider).canUseBiometrics;
    final categories = TransactionCategory.defaults;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar.large(
          title: Text(isArabic ? '⚙️ الإعدادات' : '⚙️ Settings'),
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
                      _settingsTile(
                        icon: Icons.language,
                        title: isArabic ? 'اللغة' : 'Language',
                        subtitle: isArabic ? 'العربية' : 'English',
                        trailing: Switch(
                          value: isArabic,
                          onChanged: (_) {
                            ref.read(settingsStateProvider.notifier).toggleLanguage();
                          },
                        ),
                      ),
                      const Divider(color: Colors.white10),
                      _settingsTile(
                        icon: Icons.fingerprint,
                        title: isArabic ? 'بصمة الإصبع' : 'Fingerprint',
                        subtitle: canBio
                            ? (isArabic ? 'متاحة' : 'Available')
                            : (isArabic ? 'غير متاحة' : 'Not available'),
                        trailing: canBio
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.cancel, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  child: Column(
                    children: [
                      _settingsTile(
                        icon: Icons.lock,
                        title: isArabic ? 'PIN الحماية' : 'PIN Security',
                        subtitle: hasPin
                            ? (isArabic ? 'مفعّل' : 'Active')
                            : (isArabic ? 'غير مفعّل' : 'Not set'),
                        onTap: () => setState(() => _showPinSetup = !_showPinSetup),
                      ),
                      if (_showPinSetup) ...[
                        if (hasPin)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: FilledButton(
                              onPressed: _removePin,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(isArabic ? 'إزالة PIN' : 'Remove PIN'),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: isArabic ? 'أدخل PIN (4 أرقام)' : 'Enter PIN (4 digits)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.length == 4) {
                                _setupPin(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  child: Column(
                    children: [
                      _settingsTile(
                        icon: Icons.account_balance_wallet,
                        title: isArabic ? 'تعيين ميزانية' : 'Set Budget',
                        subtitle: isArabic ? 'حدد فئة ومبلغ' : 'Choose category and amount',
                        onTap: () => setState(() => _showBudgetSetup = !_showBudgetSetup),
                      ),
                      if (_showBudgetSetup) ...[
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  hintText: isArabic ? 'اختر الفئة' : 'Select category',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: categories.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.localizedName(isArabic)),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedCategory = v),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: isArabic ? 'المبلغ' : 'Amount',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onSubmitted: (v) {
                                  if (_selectedCategory != null && v.isNotEmpty) {
                                    _saveBudget(
                                      _selectedCategory!,
                                      double.tryParse(v) ?? 0,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () {
                                  if (_selectedCategory != null && _amountController.text.isNotEmpty) {
                                    _saveBudget(
                                      _selectedCategory!,
                                      double.tryParse(_amountController.text) ?? 0,
                                    );
                                  }
                                },
                                child: Text(isArabic ? 'حفظ الميزانية' : 'Save Budget'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  child: Column(
                    children: [
                      _settingsTile(
                        icon: Icons.delete_forever,
                        title: isArabic ? 'مسح جميع البيانات' : 'Clear All Data',
                        subtitle: isArabic ? 'حذف نهائي لكل شيء' : 'Permanent delete everything',
                        onTap: _showDeleteConfirmation,
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Vault v2.1',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic ? '100% محلي • بدون إنترنت • خصوصية كاملة' : '100% Local • Offline • Full Privacy',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
