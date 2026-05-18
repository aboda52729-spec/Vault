class NumberExtractor {
  static final RegExp _numberRegex = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d+)?)');

  static List<RegExpMatch> findAll(String text) {
    return _numberRegex.allMatches(text).toList();
  }

  static double parseAmount(String raw) {
    return double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
  }

  static int? findAmountIndex(String sms, List<RegExpMatch> matches) {
    final keywords = [
      'debited', 'credited', 'amount',
      'خصم', 'إيداع', 'بمبلغ', 'مبلغ', 'قيمة', 'مدين', 'دائن',
    ];
    for (int i = 0; i < matches.length; i++) {
      final textBefore = sms.substring(0, matches[i].start).toLowerCase();
      final hasKeyword = keywords.any((kw) => textBefore.contains(kw));
      final hasBalance = [
        'balance', 'الرصيد', 'رصيدك', 'رصيد',
      ].any((kw) => textBefore.contains(kw));
      if (hasKeyword && !hasBalance) return i;
    }
    return null;
  }

  static int? findBalanceIndex(String sms, List<RegExpMatch> matches) {
    final keywords = ['balance', 'الرصيد', 'رصيدك', 'رصيد', 'الرصيد الحالي'];
    for (int i = matches.length - 1; i >= 0; i--) {
      final textBefore = sms.substring(0, matches[i].start).toLowerCase();
      if (keywords.any((kw) => textBefore.contains(kw))) return i;
    }
    return null;
  }

  static bool isDebit(String sms) {
    return [
      'debited', 'خصم', 'سحب', 'شراء', 'مدين', 'دفع',
      'withdrawal', 'payment',
    ].any((kw) => sms.contains(kw));
  }
}
