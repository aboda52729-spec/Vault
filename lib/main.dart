import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  runApp(
    ChangeNotifierProvider(
      create: (context) => BankakStore(prefs, secureStorage),
      child: const BankakApp(),
    ),
  );
}

// --- MODELS ---

enum TransactionType { debit, credit }

class BankakTransaction {
  final String id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final TransactionType type;
  final double balanceAfter;

  BankakTransaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.type,
    required this.balanceAfter,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'description': description,
        'category': category,
        'date': date.toIso8601String(),
        'type': type.index,
        'balanceAfter': balanceAfter,
      };

  factory BankakTransaction.fromJson(Map<String, dynamic> json) => BankakTransaction(
        id: json['id'],
        amount: json['amount'],
        description: json['description'],
        category: json['category'],
        date: DateTime.parse(json['date']),
        type: TransactionType.values[json['type']],
        balanceAfter: json['balanceAfter'],
      );
}

// --- STORE ---

class BankakStore extends ChangeNotifier {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  double _balance = 0.0;
  List<BankakTransaction> _transactions = [];
  bool _isArabic = true;

  BankakStore(this._prefs, this._secureStorage) {
    _loadData();
  }

  double get balance => _balance;
  List<BankakTransaction> get transactions => _transactions;
  bool get isArabic => _isArabic;

  void _loadData() async {
    // Non-sensitive data remains in SharedPreferences
    _isArabic = _prefs.getBool('isArabic') ?? true;

    // Sensitive financial data is moved to SecureStorage
    final balanceStr = await _secureStorage.read(key: 'balance');
    _balance = double.tryParse(balanceStr ?? '') ?? 0.0;

    final txJson = await _secureStorage.read(key: 'transactions');
    if (txJson != null) {
      final List decoded = json.decode(txJson);
      _transactions = decoded.map((e) => BankakTransaction.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    await _prefs.setBool('isArabic', _isArabic);

    // Encrypt and save financial data
    await _secureStorage.write(key: 'balance', value: _balance.toString());
    final txJson = json.encode(_transactions.map((e) => e.toJson()).toList());
    await _secureStorage.write(key: 'transactions', value: txJson);
  }

  void toggleLanguage() {
    _isArabic = !_isArabic;
    _saveData();
    notifyListeners();
  }

  void setInitialBalance(double amount) {
    _balance = amount;
    _saveData();
    notifyListeners();
  }

  void processBankakSMS(String sms) {
    // ADVANCED PARSER LOGIC: Uses proximity to keywords to distinguish between
    // Account numbers, Transaction amounts, and the Final Balance.
    
    final numberRegex = RegExp(r'(\d{1,3}(,\d{3})*(\.\d+)?)');
    final matches = numberRegex.allMatches(sms).toList();

    if (matches.isNotEmpty) {
      double amount = 0.0;
      double newBalance = _balance;

      // Identify Amount: Look for number preceded by "amount", "debited", "خصم", etc.
      final amountKeywords = ['debited', 'credited', 'amount', 'خصم', 'إيداع', 'بمبلغ'];
      int amountIndex = -1;

      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];
        final textBefore = sms.substring(0, match.start).toLowerCase();
        if (amountKeywords.any((kw) => textBefore.contains(kw))) {
           // We found a candidate, but let's make sure it's not the balance
           if (!textBefore.contains('balance') && !textBefore.contains('الرصيد')) {
             amountIndex = i;
             break;
           }
        }
      }
      
      // If no keyword found, assume first is amount (legacy)
      final amountStr = (amountIndex != -1 ? matches[amountIndex] : matches.first).group(0)!.replaceAll(',', '');
      amount = double.tryParse(amountStr) ?? 0.0;

      // Identify Balance: Look for number preceded by "Balance" or "الرصيد"
      final balanceKeywords = ['balance', 'الرصيد', 'رصيدك'];
      int balanceIndex = -1;
      for (int i = matches.length - 1; i >= 0; i--) {
        final match = matches[i];
        final textBefore = sms.substring(0, match.start).toLowerCase();
        if (balanceKeywords.any((kw) => textBefore.contains(kw))) {
          balanceIndex = i;
          break;
        }
      }

      if (balanceIndex != -1) {
        final balanceStr = matches[balanceIndex].group(0)!.replaceAll(',', '');
        newBalance = double.tryParse(balanceStr) ?? _balance;
      } else {
        // Fallback
        final isDebit = sms.contains('debited') || sms.contains('خصم') || sms.contains('سحب');
        newBalance = isDebit ? _balance - amount : _balance + amount;
      }

      final isDebit = sms.contains('debited') || sms.contains('خصم') || sms.contains('سحب');

      final tx = BankakTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        description: _generateDescription(sms, isDebit),
        category: _autoCategorize(sms),
        date: DateTime.now(),
        type: isDebit ? TransactionType.debit : TransactionType.credit,
        balanceAfter: newBalance,
      );

      _transactions.insert(0, tx);
      _balance = newBalance;
      _saveData();
      notifyListeners();
    }
  }

  String _generateDescription(String sms, bool isDebit) {
    if (sms.contains('electricity') || sms.contains('كهرباء')) return isArabic ? 'شراء كهرباء' : 'Electricity Purchase';
    if (sms.contains('transfer') || sms.contains('تحويل')) return isArabic ? 'تحويل بنكي' : 'Bank Transfer';
    if (sms.contains('restaurant') || sms.contains('مطعم')) return isArabic ? 'دفع مطعم' : 'Restaurant Payment';
    return isDebit
      ? (isArabic ? 'عملية سحب / خصم' : 'Debit Transaction')
      : (isArabic ? 'عملية إيداع' : 'Credit Transaction');
  }

  String _autoCategorize(String sms) {
    if (sms.contains('electricity') || sms.contains('كهرباء')) return 'Bills';
    if (sms.contains('restaurant') || sms.contains('مطعم')) return 'Food';
    if (sms.contains('transfer') || sms.contains('تحويل')) return 'Transfer';
    return 'Other';
  }

  void clearAll() {
    _balance = 0.0;
    _transactions.clear();
    _saveData();
    notifyListeners();
  }
}

// --- UI ---

class BankakApp extends StatelessWidget {
  const BankakApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BankakStore>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bankak Analytics',
      locale: Locale(store.isArabic ? 'ar' : 'en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueAccent,
        textTheme: store.isArabic 
          ? GoogleFonts.alexandriaTextTheme(ThemeData.dark().textTheme)
          : GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainDashboard(),
    );
  }
}

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
                  _BalanceCard(store: store),
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
                return _TransactionItem(tx: tx, isArabic: store.isArabic);
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
                    children: const [
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

class _BalanceCard extends StatelessWidget {
  final BankakStore store;
  const _BalanceCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.verified_user_rounded, size: 150, color: Colors.white.withValues(alpha: 0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  store.isArabic ? 'الرصيد المتوفر' : 'Available Balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      fmt.format(store.balance),
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SDG',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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

class _TransactionItem extends StatelessWidget {
  final BankakTransaction tx;
  final bool isArabic;
  const _TransactionItem({required this.tx, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final isDebit = tx.type == TransactionType.debit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDebit ? Colors.redAccent.withValues(alpha: 0.1) : Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isDebit ? Icons.south_east_rounded : Icons.north_east_rounded,
                color: isDebit ? Colors.redAccent : Colors.greenAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tx.category,
                          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(tx.date),
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDebit ? '-' : '+'}${fmt.format(tx.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDebit ? Colors.white : Colors.greenAccent,
                  ),
                ),
                Text(
                  fmt.format(tx.balanceAfter),
                  style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.2)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
