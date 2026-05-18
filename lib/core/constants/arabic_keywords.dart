class ArabicKeywords {
  ArabicKeywords._();

  static const List<String> bankIdentification = [
    'bok',
    'bankak',
    'بنك الخرطوم',
    'Bank of Khartoum',
    'BOK',
  ];

  static const List<String> amount = [
    'debited',
    'credited',
    'amount',
    'خصم',
    'إيداع',
    'بمبلغ',
    'مبلغ',
    'قيمة',
    'مدين',
    'دائن',
  ];

  static const List<String> balance = [
    'balance',
    'الرصيد',
    'رصيدك',
    'رصيد',
    'الرصيد الحالي',
  ];

  static const List<String> debit = [
    'debited',
    'خصم',
    'سحب',
    'شراء',
    'مدين',
    'دفع',
    'withdrawal',
    'payment',
  ];

  static const List<String> credit = [
    'credited',
    'إيداع',
    'وارد',
    'دائن',
    'deposit',
  ];

  static const Map<String, String> categoryKeywords = {
    'Bills': 'كهرباء, electricity, فاتورة, bill',
    'Food': 'مطعم, restaurant, طعام, food, كافيه, cafe',
    'Transfer': 'تحويل, transfer, حوالة, remittance',
    'Telecom': 'رصيد, زين, سوداني, mtc, zain, sudani, اتصالات',
    'Fuel': 'بنزين, petrol, fuel, غاز, محطة, station',
    'Shopping': 'تسوق, shop, متجر, store, بقالة, supermarket',
  };

}
