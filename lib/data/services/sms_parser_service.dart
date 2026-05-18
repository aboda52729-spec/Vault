import '../../core/constants/arabic_keywords.dart';
import '../../core/utils/extractors.dart';
import '../models/transaction.dart';

class SmsParseResult {
  final double amount;
  final double? balanceAfter;
  final bool isDebit;
  final String description;
  final String category;

  SmsParseResult({
    required this.amount,
    this.balanceAfter,
    required this.isDebit,
    required this.description,
    required this.category,
  });
}

class SmsParserService {
  static SmsParseResult parse(String sms, {bool isArabic = true}) {
    final matches = NumberExtractor.findAll(sms);

    if (matches.isEmpty) {
      return SmsParseResult(
        amount: 0,
        isDebit: true,
        description: _defaultDescription(true, isArabic),
        category: 'Other',
      );
    }

    final amountIndex = NumberExtractor.findAmountIndex(sms, matches);
    final balanceIndex = NumberExtractor.findBalanceIndex(sms, matches);

    final amountStr = amountIndex != null
        ? matches[amountIndex].group(0)!
        : matches.first.group(0)!;
    final amount = NumberExtractor.parseAmount(amountStr);

    double? balanceAfter;
    if (balanceIndex != null) {
      balanceAfter = NumberExtractor.parseAmount(
        matches[balanceIndex].group(0)!,
      );
    }

    final isDebit = NumberExtractor.isDebit(sms);
    final category = _autoCategorize(sms);
    final description = _generateDescription(sms, isDebit, isArabic);

    return SmsParseResult(
      amount: amount,
      balanceAfter: balanceAfter,
      isDebit: isDebit,
      description: description,
      category: category,
    );
  }

  static BankakTransaction toTransaction(
    SmsParseResult result, {
    required String id,
    required DateTime? date,
    required double currentBalance,
  }) {
    final newBalance = result.balanceAfter ??
        (result.isDebit ? currentBalance - result.amount : currentBalance + result.amount);

    return BankakTransaction(
      id: id,
      amount: result.amount,
      description: result.description,
      category: result.category,
      date: date ?? DateTime.now(),
      typeIndex: result.isDebit ? 0 : 1,
      balanceAfter: newBalance,
    );
  }

  static String _generateDescription(String sms, bool isDebit, bool isArabic) {
    if (sms.contains('electricity') || sms.contains('كهرباء')) {
      return isArabic ? 'فواتير كهرباء' : 'Electricity Bills';
    }
    if (sms.contains('transfer') || sms.contains('تحويل')) {
      return isArabic ? 'تحويل بنكي' : 'Bank Transfer';
    }
    if (sms.contains('restaurant') || sms.contains('مطعم')) {
      return isArabic ? 'مطعم' : 'Restaurant';
    }
    if (sms.contains('رصيد') || sms.contains('زين') || sms.contains('سوداني') || sms.contains('mtc')) {
      return isArabic ? 'رصيد موبايل' : 'Mobile Top-up';
    }
    if (sms.contains('بنزين') || sms.contains('petrol') || sms.contains('fuel')) {
      return isArabic ? 'وقود' : 'Fuel';
    }
    if (sms.contains('تسوق') || sms.contains('shop') || sms.contains('بقالة')) {
      return isArabic ? 'مشتريات' : 'Shopping';
    }
    return isDebit
        ? (isArabic ? 'عملية خصم' : 'Debit Transaction')
        : (isArabic ? 'عملية إيداع' : 'Credit Transaction');
  }

  static String _autoCategorize(String sms) {
    for (final entry in ArabicKeywords.categoryKeywords.entries) {
      final keywords = entry.value.split(', ');
      if (keywords.any((kw) => sms.contains(kw))) {
        return entry.key;
      }
    }
    return 'Other';
  }

  static String _defaultDescription(bool isDebit, bool isArabic) {
    return isDebit
        ? (isArabic ? 'عملية خصم' : 'Debit Transaction')
        : (isArabic ? 'عملية إيداع' : 'Credit Transaction');
  }
}
