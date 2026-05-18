import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  final txRepo = ref.watch(transactionRepositoryProvider);
  final dashState = ref.watch(dashboardProvider);
  return TransactionsNotifier(txRepo, dashState.isArabic);
});

class TransactionsState {
  final List<BankakTransaction> transactions;
  final bool isArabic;
  final String searchQuery;
  final String? categoryFilter;

  TransactionsState({
    required this.transactions,
    required this.isArabic,
    this.searchQuery = '',
    this.categoryFilter,
  });

  TransactionsState copyWith({
    List<BankakTransaction>? transactions,
    bool? isArabic,
    String? searchQuery,
    String? categoryFilter,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isArabic: isArabic ?? this.isArabic,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter,
    );
  }

  List<BankakTransaction> get filteredTransactions {
    var result = transactions;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((t) =>
        t.description.toLowerCase().contains(q) ||
        t.category.toLowerCase().contains(q)
      ).toList();
    }
    if (categoryFilter != null && categoryFilter!.isNotEmpty) {
      result = result.where((t) => t.category == categoryFilter).toList();
    }
    return result;
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionRepository _txRepo;

  TransactionsNotifier(this._txRepo, bool isArabic)
      : super(TransactionsState(
          transactions: _txRepo.getAll(),
          isArabic: isArabic,
        ));

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String? category) {
    state = state.copyWith(categoryFilter: category);
  }

  void refresh() {
    state = state.copyWith(transactions: _txRepo.getAll());
  }
}
