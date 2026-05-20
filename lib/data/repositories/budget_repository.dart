import 'package:hive_flutter/hive_flutter.dart';
import '../features/budget/models/budget.dart';

class BudgetRepository {
  static const String _boxName = 'budgets';
  late Box<BudgetEntry> _box;

  Future<void> init() async {
    _box = await Hive.openBox<BudgetEntry>(_boxName);
  }

  List<BudgetEntry> getBudgets(int month, int year) {
    return _box.values
      .where((b) => b.month == month && b.year == year)
      .toList();
  }

  BudgetEntry? getBudgetForCategory(String category, int month, int year) {
    return _box.values.where(
      (b) => b.category == category && b.month == month && b.year == year,
    ).firstOrNull;
  }

  Future<void> setBudget(String category, double amount, int month, int year) async {
    final existing = getBudgetForCategory(category, month, year);
    if (existing != null) {
      _box.delete(existing.id);
    }
    final entry = BudgetEntry(
      id: '${category}_$month' ,
      category: category,
      amount: amount,
      month: month,
      year: year,
    );
    await _box.put(entry.id, entry);
  }

  Future<void> deleteBudget(String category, int month, int year) async {
    final existing = getBudgetForCategory(category, month, year);
    if (existing != null) {
      await _box.delete(existing.id);
    }
  }

  double getSpentPercentage(String category, double spent, int month, int year) {
    final budget = getBudgetForCategory(category, month, year);
    if (budget == null) return 0;
    return (spent / budget.amount) * 100;
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
