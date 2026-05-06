import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/transaction.dart';
import 'sms_service.dart';

class BankakStore extends ChangeNotifier {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final SmsService _smsService = SmsService();
  
  double _balance = 0.0;
  List<BankakTransaction> _transactions = [];
  bool _isArabic = true;
  bool _isSyncing = false;

  BankakStore(this._prefs, this._secureStorage) {
    _loadData();
  }

  double get balance => _balance;
  List<BankakTransaction> get transactions => _transactions;
  bool get isArabic => _isArabic;
  bool get isSyncing => _isSyncing;

  void _loadData() async {
    _isArabic = _prefs.getBool('isArabic') ?? true;

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

  Future<void> syncWithPhoneSMS() async {
    _isSyncing = true;
    notifyListeners();

    try {
      final messages = await _smsService.getBankakMessages();
      if (messages.isEmpty) return;

      _transactions.clear();
      
      // Sort oldest to newest to ensure balance updates correctly
      messages.sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

      for (var msg in messages) {
        if (msg.body == null) continue;
        processBankakSMS(msg.body!, date: msg.date, id: msg.id?.toString());
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void processBankakSMS(String sms, {DateTime? date, String? id}) {
    final numberRegex = RegExp(r'(\d{1,3}(,\d{3})*(\.\d+)?)');
    final matches = numberRegex.allMatches(sms).toList();

    if (matches.isNotEmpty) {
      double amount = 0.0;
      double newBalance = _balance;

      // Logic to find which number is the "Amount"
      final amountKeywords = ['debited', 'credited', 'amount', 'خصم', 'إيداع', 'بمبلغ'];
      int amountIndex = -1;
      
      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];
        final textBefore = sms.substring(0, match.start).toLowerCase();
        if (amountKeywords.any((kw) => textBefore.contains(kw))) {
           if (!textBefore.contains('balance') && !textBefore.contains('الرصيد')) {
             amountIndex = i;
             break;
           }
        }
      }
      
      final amountStr = (amountIndex != -1 ? matches[amountIndex] : matches.first).group(0)!.replaceAll(',', '');
      amount = double.tryParse(amountStr) ?? 0.0;

      // Logic to find which number is the "Balance"
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
        final isDebit = sms.contains('debited') || sms.contains('خصم') || sms.contains('سحب') || sms.contains('شراء');
        newBalance = isDebit ? _balance - amount : _balance + amount;
      }

      final isDebit = sms.contains('debited') || sms.contains('خصم') || sms.contains('سحب') || sms.contains('شراء');

      final tx = BankakTransaction(
        id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        description: _generateDescription(sms, isDebit),
        category: _autoCategorize(sms),
        date: date ?? DateTime.now(),
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
    if (sms.contains('electricity') || sms.contains('كهرباء')) return _isArabic ? 'شراء كهرباء' : 'Electricity Purchase';
    if (sms.contains('transfer') || sms.contains('تحويل')) return _isArabic ? 'تحويل بنكي' : 'Bank Transfer';
    if (sms.contains('restaurant') || sms.contains('مطعم')) return _isArabic ? 'دفع مطعم' : 'Restaurant Payment';
    if (sms.contains('رصيد') || sms.contains('زين') || sms.contains('سوداني')) return _isArabic ? 'شراء رصيد' : 'Mobile Top-up';
    
    return isDebit 
      ? (_isArabic ? 'عملية سحب / خصم' : 'Debit Transaction')
      : (_isArabic ? 'عملية إيداع' : 'Credit Transaction');
  }

  String _autoCategorize(String sms) {
    if (sms.contains('electricity') || sms.contains('كهرباء')) return 'Bills';
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
