import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/monthly_summary.dart';

class TransactionRepository {
  static const String _boxName = 'transactions';
  static const String _balanceKey = 'balance';

  final FlutterSecureStorage _secureStorage;
  late Box<BankakTransaction> _box;

  TransactionRepository(this._secureStorage);

  Future<void> init() async {
    _box = await Hive.openBox<BankakTransaction>(_boxName);
  }

  List<BankakTransaction> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<BankakTransaction> getByMonth(int year, int month) {
    return _box.values
      .where((t) => t.date.year == year && t.date.month == month)
      .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<BankakTransaction> getByCategory(String category) {
    return _box.values
      .where((t) => t.category == category)
      .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<BankakTransaction> getByType(bool isDebit) {
    final index = isDebit ? 0 : 1;
    return _box.values
      .where((t) => t.typeIndex == index)
      .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<BankakTransaction> search(String query) {
    final q = query.toLowerCase();
    return _box.values
      .where((t) =>
        t.description.toLowerCase().contains(q) ||
        t.category.toLowerCase().contains(q))
      .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTotalByCategory(String category, {int? year, int? month}) {
    var txns = _box.values.where((t) => t.category == category);
    if (year != null) {
      txns = txns.where((t) => t.date.year == year);
    }
    if (month != null) {
      txns = txns.where((t) => t.date.month == month);
    }
    return txns.fold<double>(0, (sum, t) => sum + t.amount);
  }

  MonthlySummary? getMonthlySummary(int year, int month) {
    final txns = getByMonth(year, month);
    if (txns.isEmpty) return null;
    final income = txns.where((t) => !t.isDebit).fold<double>(0, (s, t) => s + t.amount);
    final expense = txns.where((t) => t.isDebit).fold<double>(0, (s, t) => s + t.amount);
    final lastBefore = _box.values
      .where((t) => t.date.isBefore(DateTime(year, month, 1)))
      .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final startBalance = lastBefore.isNotEmpty ? lastBefore.first.balanceAfter : 0.0;
    return MonthlySummary(
      year: year,
      month: month,
      totalIncome: income,
      totalExpense: expense,
      startingBalance: startBalance,
      endingBalance: txns.last.balanceAfter,
    );
  }

  List<MonthlySummary> getMonthlySummaries({int months = 12}) {
    final now = DateTime.now();
    return List.generate(months, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return getMonthlySummary(d.year, d.month);
    }).whereType<MonthlySummary>().toList();
  }

  Future<double> getBalance() async {
    final str = await _secureStorage.read(key: _balanceKey);
    return double.tryParse(str ?? '') ?? 0.0;
  }

  Future<void> setBalance(double balance) async {
    await _secureStorage.write(key: _balanceKey, value: balance.toString());
  }

  void add(BankakTransaction tx) {
    _box.put(tx.id, tx);
  }

  void delete(String id) {
    _box.delete(id);
  }

  void clear() {
    _box.clear();
  }

  Future<void> clearAll() async {
    await _box.clear();
    await _secureStorage.delete(key: _balanceKey);
  }

  double get totalBalance {
    return _box.values.fold<double>(0, (sum, t) => t.isDebit ? sum - t.amount : sum + t.amount);
  }

  Map<String, double> get categoryTotals {
    final map = <String, double>{};
    for (final t in _box.values.where((t) => t.isDebit)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }
}
