import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/bankak_store.dart';
import '../../models/transaction.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_item.dart';

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BankakStore>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: Colors.black,
            title: Text(
              store.isArabic ? 'تحليلات بنكك' : 'Bankak Analytics',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.translate_rounded),
                onPressed: () => store.toggleLanguage(),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => store.clearAll(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BalanceCard(store: store),
                  const SizedBox(height: 30),
                  _SectionHeader(
                    title: store.isArabic ? 'محاكاة رسائل بنكك' : 'Simulate Bankak SMS',
                    subtitle: store.isArabic ? 'اختبر كيف يقرأ التطبيق بياناتك' : 'Test how the app reads your data',
                  ),
                  const SizedBox(height: 15),
                  _SmsSimulationPanel(store: store),
                  const SizedBox(height: 30),
                  _SectionHeader(
                    title: store.isArabic ? 'العمليات الأخيرة' : 'Recent Transactions',
                    subtitle: store.isArabic ? 'مزامنة تلقائية من الرسائل' : 'Auto-synced from SMS',
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tx = store.transactions[index];
                return TransactionItem(tx: tx, isArabic: store.isArabic);
              },
              childCount: store.transactions.length,
            ),
          ),
          if (store.transactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Opacity(
                  opacity: 0.5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 64),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showSetBalanceDialog(context, store);
        },
        label: Text(store.isArabic ? 'تعديل الرصيد' : 'Adjust Balance'),
        icon: const Icon(Icons.account_balance_wallet_rounded),
      ),
    );
  }

  void _showSetBalanceDialog(BuildContext context, BankakStore store) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(store.isArabic ? 'تعيين الرصيد الحالي' : 'Set Current Balance'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '0.00',
            suffixText: 'SDG',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(store.isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              store.setInitialBalance(val);
              Navigator.pop(context);
            },
            child: Text(store.isArabic ? 'حفظ' : 'Save'),
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(128))),
      ],
    );
  }
}

class _SmsSimulationPanel extends StatelessWidget {
  final BankakStore store;
  const _SmsSimulationPanel({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        children: [
          _SmsButton(
            label: 'Deduction (English)',
            sms: 'Bank of Khartoum: Your account has been debited by 12,500.00 SDG. Ref: 98765. Balance: 137,500.00 SDG.',
            onTap: () => store.processBankakSMS('Bank of Khartoum: Your account has been debited by 12,500.00 SDG. Ref: 98765. Balance: 137,500.00 SDG.'),
          ),
          const Divider(height: 20, color: Colors.white10),
          _SmsButton(
            label: 'إيداع (عربي)',
            sms: 'بنك الخرطوم: تم إيداع 25,000.00 ج.س في حسابك. الرصيد الحالي: 162,500.00 ج.س',
            onTap: () => store.processBankakSMS('بنك الخرطوم: تم إيداع 25,000.00 ج.س في حسابك. الرصيد الحالي: 162,500.00 ج.س'),
          ),
          const Divider(height: 20, color: Colors.white10),
          _SmsButton(
            label: 'Electricity (Arabic)',
            sms: 'بنك الخرطوم: تم خصم 3,000.00 ج.س مقابل كهرباء. المرجع: 1122. الرصيد: 159,500.00 ج.س',
            onTap: () => store.processBankakSMS('بنك الخرطوم: تم خصم 3,000.00 ج.س مقابل كهرباء. المرجع: 1122. الرصيد: 159,500.00 ج.س'),
          ),
        ],
      ),
    );
  }
}

class _SmsButton extends StatelessWidget {
  final String label;
  final String sms;
  final VoidCallback onTap;
  const _SmsButton({required this.label, required this.sms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            const Icon(Icons.sms_rounded, size: 16, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(sms, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white38)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
