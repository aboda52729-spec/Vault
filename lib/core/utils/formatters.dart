import 'package:intl/intl.dart';

class AppFormatters {
  static final _currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
  static final _dateFormat = DateFormat('MMM dd, HH:mm');
  static final _monthFormat = DateFormat('MMM yyyy');

  static String formatAmount(double amount) => _currencyFormat.format(amount);
  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatMonth(DateTime date) => _monthFormat.format(date);

  static String formatWithSign(double amount, {required bool isDebit}) {
    return '${isDebit ? '-' : '+'}${_currencyFormat.format(amount)}';
  }
}
