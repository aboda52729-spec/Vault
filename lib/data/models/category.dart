class TransactionCategory {
  final String id;
  final String nameEn;
  final String nameAr;
  final int colorValue;
  final String iconName;

  const TransactionCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.colorValue,
    required this.iconName,
  });

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;

  static const List<TransactionCategory> defaults = [
    TransactionCategory(
      id: 'Bills',
      nameEn: 'Bills',
      nameAr: 'فواتير',
      colorValue: 0xFFFF6B6B,
      iconName: 'receipt_long',
    ),
    TransactionCategory(
      id: 'Food',
      nameEn: 'Food',
      nameAr: 'طعام',
      colorValue: 0xFFFFA94D,
      iconName: 'restaurant',
    ),
    TransactionCategory(
      id: 'Transfer',
      nameEn: 'Transfer',
      nameAr: 'تحويل',
      colorValue: 0xFF4A7CF7,
      iconName: 'swap_horiz',
    ),
    TransactionCategory(
      id: 'Telecom',
      nameEn: 'Telecom',
      nameAr: 'اتصالات',
      colorValue: 0xFFA855F7,
      iconName: 'phone_android',
    ),
    TransactionCategory(
      id: 'Fuel',
      nameEn: 'Fuel',
      nameAr: 'وقود',
      colorValue: 0xFF22C55E,
      iconName: 'local_gas_station',
    ),
    TransactionCategory(
      id: 'Shopping',
      nameEn: 'Shopping',
      nameAr: 'تسوق',
      colorValue: 0xFFEC4899,
      iconName: 'shopping_bag',
    ),
    TransactionCategory(
      id: 'Other',
      nameEn: 'Other',
      nameAr: 'أخرى',
      colorValue: 0xFF9CA3AF,
      iconName: 'more_horiz',
    ),
  ];

  static TransactionCategory fromId(String id) {
    return defaults.firstWhere(
      (c) => c.id == id,
      orElse: () => defaults.last,
    );
  }
}
