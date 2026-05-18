import 'package:flutter_test/flutter_test.dart';
import 'package:bankak_analytics/core/utils/extractors.dart';

void main() {
  group('NumberExtractor', () {
    test('finds all numbers in text', () {
      final matches = NumberExtractor.findAll('خصم 15,000 SDG. الرصيد 135,000');
      expect(matches.length, equals(2));
    });

    test('parses comma-formatted amount', () {
      expect(NumberExtractor.parseAmount('1,500'), equals(1500.0));
      expect(NumberExtractor.parseAmount('1,500,000'), equals(1500000.0));
      expect(NumberExtractor.parseAmount('1500'), equals(1500.0));
      expect(NumberExtractor.parseAmount('1,234.56'), equals(1234.56));
    });

    test('detects debit keywords', () {
      expect(NumberExtractor.isDebit('خصم 5,000'), isTrue);
      expect(NumberExtractor.isDebit('تم السحب'), isTrue);
      expect(NumberExtractor.isDebit('عملية شراء'), isTrue);
      expect(NumberExtractor.isDebit('دفع فاتورة'), isTrue);
      expect(NumberExtractor.isDebit('تم الإيداع'), isFalse);
      expect(NumberExtractor.isDebit('credited 5,000'), isFalse);
    });

    test('finds amount index correctly', () {
      final sms = 'تم خصم مبلغ 15,000 SDG. الرصيد الحالي 135,000';
      final matches = NumberExtractor.findAll(sms);
      final amountIndex = NumberExtractor.findAmountIndex(sms, matches);
      expect(amountIndex, equals(0));
      expect(matches[amountIndex!].group(0), equals('15,000'));
    });

    test('finds balance index correctly', () {
      final sms = 'تم خصم مبلغ 15,000 SDG. الرصيد الحالي 135,000';
      final matches = NumberExtractor.findAll(sms);
      final balanceIndex = NumberExtractor.findBalanceIndex(sms, matches);
      expect(balanceIndex, equals(1));
      expect(matches[balanceIndex!].group(0), equals('135,000'));
    });
  });
}
