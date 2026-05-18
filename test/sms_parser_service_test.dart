import 'package:flutter_test/flutter_test.dart';
import 'package:bankak_analytics/data/services/sms_parser_service.dart';

void main() {
  group('SmsParserService.parse', () {
    test('parses Arabic debit SMS with amount and balance', () {
      final sms = 'تم خصم مبلغ 15,000 SDG من حسابك. الرصيد الحالي: 135,000 SDG';
      final result = SmsParserService.parse(sms);
      expect(result.amount, equals(15000.0));
      expect(result.balanceAfter, equals(135000.0));
      expect(result.isDebit, isTrue);
    });

    test('parses Arabic credit SMS', () {
      final sms = 'تم إيداع مبلغ 50,000 SDG. رصيدك 250,000 SDG';
      final result = SmsParserService.parse(sms);
      expect(result.amount, equals(50000.0));
      expect(result.balanceAfter, equals(250000.0));
      expect(result.isDebit, isFalse);
    });

    test('parses English debit SMS', () {
      final sms = 'Your account has been debited with SDG 5,000. Balance: SDG 45,000';
      final result = SmsParserService.parse(sms);
      expect(result.amount, equals(5000.0));
      expect(result.balanceAfter, equals(45000.0));
      expect(result.isDebit, isTrue);
    });

    test('recognizes electricity category', () {
      final sms = 'شراء كهرباء بمبلغ 10,000 SDG';
      final result = SmsParserService.parse(sms);
      expect(result.category, equals('Bills'));
      expect(result.description, contains('كهرباء'));
    });

    test('recognizes restaurant category', () {
      final sms = 'دفع في مطعم 3,500 SDG';
      final result = SmsParserService.parse(sms);
      expect(result.category, equals('Food'));
    });

    test('recognizes transfer category', () {
      final sms = 'تحويل بنكي بمبلغ 20,000 SDG';
      final result = SmsParserService.parse(sms);
      expect(result.category, equals('Transfer'));
    });

    test('recognizes telecom category', () {
      final sms = 'شراء رصيد زين 1,000 SDG';
      final result = SmsParserService.parse(sms);
      expect(result.category, equals('Telecom'));
    });

    test('handles sms without numbers', () {
      final sms = 'مرحباً بك في بنك الخرطوم';
      final result = SmsParserService.parse(sms);
      expect(result.amount, equals(0));
      expect(result.category, equals('Other'));
    });

    test('determines debit from keywords', () {
      expect(SmsParserService.parse('خصم 5,000').isDebit, isTrue);
      expect(SmsParserService.parse('سحب 2,000').isDebit, isTrue);
      expect(SmsParserService.parse('شراء 1,000').isDebit, isTrue);
      expect(SmsParserService.parse('دفع 500').isDebit, isTrue);
      expect(SmsParserService.parse('إيداع 10,000').isDebit, isFalse);
    });

    test('parses sms with comma-formatted large numbers', () {
      final sms = 'إيداع مبلغ 1,500,000 SDG. الرصيد 5,000,000 SDG';
      final result = SmsParserService.parse(sms);
      expect(result.amount, equals(1500000.0));
      expect(result.balanceAfter, equals(5000000.0));
    });
  });
}
