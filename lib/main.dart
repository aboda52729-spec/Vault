import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'sms_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (context) => BankakStore(prefs),
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
  final SmsService _smsService = SmsService();
  
  double _balance = 0.0;
  List<BankakTransaction> _transactions = [];
  bool _isArabic = true;
  bool _isSyncing = false;

  BankakStore(this._prefs) {
    _loadData();
  }

  double get balance => _balance;
  List<BankakTransaction> get transactions => _transactions;
  bool get isArabic => _isArabic;
  bool get isSyncing => _isSyncing;

  void _loadData() {
    _balance = _prefs.getDouble('balance') ?? 0.0;
    _isArabic = _prefs.getBool('isArabic') ?? true;
    final txJson = _prefs.getString('transactions');
    if (txJson != null) {
      final List decoded = json.decode(txJson);
      _transactions = decoded.map((e) => BankakTransaction.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    await _prefs.setDouble('balance', _balance);
    await _prefs.setBool('isArabic', _isArabic);
    final txJson = json.encode(_transactions.map((e) => e.toJson()).toList());
    await _prefs.setString('transactions', txJson);
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

  Future<void> syncWithPhoneSMS() async {
    _isSyncing = true;
    notifyListeners();

    try {
      final messages = await _smsService.getBankakMessages();
      if (messages.isEmpty) return;

      _transactions.clear();
      
      // Sort oldest to newest
      messages.sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

      for (var msg in messages) {
        if (msg.body == null) continue;
        final sms = msg.body!;
        
        // Match the first number sequence for the amount
        final amountMatch = RegExp(r'(\d{1,3}(,\d{3})*(\.\d+)?)').firstMatch(sms);
        if (amountMatch != null) {
          final amountStr = amountMatch.group(0)!.replaceAll(',', '');
          final amount = double.tryParse(amountStr) ?? 0.0;
          
          final isDebit = sms.contains('debited') || sms.contains('خصم') || sms.contains('سحب') || sms.contains('شراء');
          
          // Try to extract the remaining balance from the SMS
          double balanceAfter = 0.0;
          final balanceMatch = RegExp(r'(الرصيد:|الرصيد الحالي:|Balance:)\s*(\d{1,3}(,\d{3})*(\.\d+)?)').firstMatch(sms);
          
          if (balanceMatch != null) {
             final balStr = balanceMatch.group(2)!.replaceAll(',', '');
             balanceAfter = double.tryParse(balStr) ?? 0.0;
             _balance = balanceAfter; // Update our global balance to the latest known accurate balance
          } else {
             _balance = isDebit ? _balance - amount : _balance + amount;
             balanceAfter = _balance;
          }

          final tx = BankakTransaction(
            id: msg.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            amount: amount,
            description: _extractDescription(sms, isDebit),
            category: _autoCategorize(sms),
            date: msg.date ?? DateTime.now(),
            type: isDebit ? TransactionType.debit : TransactionType.credit,
            balanceAfter: balanceAfter,
          );

          _transactions.insert(0, tx); // Newest first
        }
      }
      _saveData();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  String _extractDescription(String sms, bool isDebit) {
    if (sms.contains('كهرباء') || sms.toLowerCase().contains('electricity')) return 'Electricity Token';
    if (sms.contains('رصيد') || sms.toLowerCase().contains('topup')) return 'Mobile Top-up';
    return isDebit ? 'Expense' : 'Deposit';
  }

  String _autoCategorize(String sms) {
    if (sms.contains('electricity') || sms.contains('كهرباء')) return 'Utilities';
    if (sms.contains('restaurant') || sms.contains('مطعم')) return 'Food';
    if (sms.contains('transfer') || sms.contains('تحويل')) return 'Transfer';
    if (sms.contains('رصيد') || sms.contains('زين') || sms.contains('سوداني')) return 'Telecom';
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

class _RealSyncPanel extends StatelessWidget {
  final BankakStore store;
  const _RealSyncPanel({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.sync_rounded, size: 40, color: Colors.blueAccent),
          const SizedBox(height: 15),
          Text(
            store.isArabic 
              ? 'سيطلب التطبيق إذن قراءة الرسائل لسحب تاريخ معاملاتك من بنك الخرطوم تلقائياً.' 
              : 'The app will request SMS permission to automatically pull your transaction history from Bank of Khartoum.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
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
