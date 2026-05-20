import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../models/budget.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  return BudgetNotifier(budgetRepo, txRepo, now.month, now.year);
});

class BudgetState {
  final List<BudgetEntry> budgets;
  final Map<String, double> categorySpent;
  final bool isLoading;
  final int selectedMonth;
  final int selectedYear;

  BudgetState({
    required this.budgets,
    required this.categorySpent,
    this.isLoading = false,
    required this.selectedMonth,
    required this.selectedYear,
  });

  BudgetState copyWith({
    List<BudgetEntry>? budgets,
    Map<String, double>? categorySpent,
    bool? isLoading,
    int? selectedMonth,
    int? selectedYear,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      categorySpent: categorySpent ?? this.categorySpent,
      isLoading: isLoading ?? this.isLoading,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }

  Map<String, double> get remainingBudget {
    final remaining = <String, double>{};
    for (final budget in budgets) {
      final spent = categorySpent[budget.category] ?? 0;
      remaining[budget.category] = budget.amount - spent;
    }
    return remaining;
  }
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetRepository _budgetRepo;
  final TransactionRepository _txRepo;

  BudgetNotifier(this._budgetRepo, this._txRepo, int month, int year)
      : super(BudgetState(
          budgets: [],
          categorySpent: {},
          selectedMonth: month,
          selectedYear: year,
        )) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final budgets = _budgetRepo.getBudgets(state.selectedMonth, state.selectedYear);
    final categorySpent = _txRepo.categoryTotals;
    state = state.copyWith(
      budgets: budgets,
      categorySpent: categorySpent,
      isLoading: false,
    );
  }

  Future<void> setBudget(String category, double amount) async {
    await _budgetRepo.setBudget(
      category,
      amount,
      state.selectedMonth,
      state.selectedYear,
    );
    await _load();
  }

  Future<void> deleteBudget(String category) async {
    await _budgetRepo.deleteBudget(
      category,
      state.selectedMonth,
      state.selectedYear,
    );
    await _load();
  }

  Future<void> changeMonth(int month, int year) async {
    state = state.copyWith(
      selectedMonth: month,
      selectedYear: year,
    );
    await _load();
  }
}
