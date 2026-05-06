import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/bankak_store.dart';
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
              store.isArabic ? 'Vault' : 'Vault',
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
                    title: store.isArabic ? 'مزامنة حقيقية' : 'Real Sync',
                    subtitle: store.isArabic ? 'اسحب بياناتك مباشرة من الرسائل' : 'Fetch data directly from SMS',
                  ),
                  const SizedBox(height: 15),
                  _RealSyncPanel(store: store),
                  const SizedBox(height: 30),
                  _SectionHeader(
                    title: store.isArabic ? 'العمليات السابقة' : 'Past Transactions',
                    subtitle: store.isArabic ? 'مزامنة من صندوق الوارد' : 'Synced from Inbox',
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Opacity(
                  opacity: 0.5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, size: 64),
                      const SizedBox(height: 10),
                      Text(store.isArabic ? 'لا توجد بيانات، قم بالمزامنة' : 'No data, please sync'),
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

class _RealSyncPanel extends StatelessWidget {
  final BankakStore store;
  const _RealSyncPanel({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        children: [
          const Icon(Icons.sync_rounded, size: 40, color: Colors.blueAccent),
          const SizedBox(height: 15),
          Text(
            store.isArabic 
              ? 'سيطلب التطبيق إذن قراءة الرسائل لسحب تاريخ معاملاتك من بنك الخرطوم تلقائياً.' 
              : 'The app will request SMS permission to automatically pull your transaction history from Bank of Khartoum.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(178)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: store.isSyncing ? null : () => store.syncWithPhoneSMS(),
              child: store.isSyncing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      store.isArabic ? 'بدء المزامنة من الرسائل' : 'Start SMS Sync',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
