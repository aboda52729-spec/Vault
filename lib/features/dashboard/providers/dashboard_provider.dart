import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/services/sms_parser_service.dart';
import '../../../data/services/sms_service.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final txRepo = ref.watch(transactionRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return DashboardNotifier(txRepo, settingsRepo);
});

class DashboardState {
  final double balance;
  final List<BankakTransaction> transactions;
  final bool isArabic;
  final bool isSyncing;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.balance = 0.0,
    this.transactions = const [],
    this.isArabic = true,
    this.isSyncing = false,
    this.isLoading = false,
    this.errorMessage,
  });

  double get monthlyIncome {
    final now = DateTime.now();
    return transactions
        .where((t) => !t.isDebit && t.date.month == now.month && t.date.year == now.year)
        .fold<double>(0, (s, t) => s + t.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    return transactions
        .where((t) => t.isDebit && t.date.month == now.month && t.date.year == now.year)
        .fold<double>(0, (s, t) => s + t.amount);
  }

  List<BankakTransaction> get recentTransactions => transactions.take(10).toList();

  DashboardState copyWith({
    double? balance,
    List<BankakTransaction>? transactions,
    bool? isArabic,
    bool? isSyncing,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isArabic: isArabic ?? this.isArabic,
      isSyncing: isSyncing ?? this.isSyncing,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final TransactionRepository _txRepo;
  final SettingsRepository _settingsRepo;
  final SmsService _smsService = SmsService();

  DashboardNotifier(this._txRepo, this._settingsRepo)
      : super(const DashboardState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final balance = await _txRepo.getBalance();
    final isArabic = _settingsRepo.isArabic;
    final transactions = _txRepo.getAll();
    state = state.copyWith(
      balance: balance,
      isArabic: isArabic,
      transactions: transactions,
      isLoading: false,
    );
  }

  void toggleLanguage() {
    final newValue = !state.isArabic;
    _settingsRepo.isArabic = newValue;
    state = state.copyWith(isArabic: newValue);
  }

  Future<void> setBalance(double amount) async {
    await _txRepo.setBalance(amount);
    state = state.copyWith(balance: amount);
  }

  Future<void> syncWithSMS() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, errorMessage: null);

    try {
      final messages = await _smsService.getBankakMessages();
      if (messages.isEmpty) {
        state = state.copyWith(
          isSyncing: false,
          errorMessage: 'No Bankak messages found',
        );
        return;
      }

      final validMessages = messages.where((m) => m.date != null).toList()
        ..sort((a, b) => a.date!.compareTo(b.date!));

      _txRepo.clear();
      var currentBalance = await _txRepo.getBalance();

      for (final msg in validMessages) {
        if (msg.body == null) continue;
        final result = SmsParserService.parse(msg.body!, isArabic: state.isArabic);
        final tx = SmsParserService.toTransaction(
          result,
          id: msg.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          date: msg.date,
          currentBalance: currentBalance,
        );
        _txRepo.add(tx);
        currentBalance = tx.balanceAfter;
      }

      await _txRepo.setBalance(currentBalance);
      state = state.copyWith(
        balance: currentBalance,
        transactions: _txRepo.getAll(),
        isSyncing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Sync failed: ${e.toString()}',
      );
    }
  }

  void processSmsBody(String smsBody) {
    final result = SmsParserService.parse(smsBody, isArabic: state.isArabic);
    final tx = SmsParserService.toTransaction(
      result,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      currentBalance: state.balance,
    );
    _txRepo.add(tx);
    _txRepo.setBalance(tx.balanceAfter);
    state = state.copyWith(
      balance: tx.balanceAfter,
      transactions: _txRepo.getAll(),
    );
  }

  void clearAll() {
    _txRepo.clear();
    _txRepo.setBalance(0.0);
    state = state.copyWith(balance: 0.0, transactions: []);
  }

  void deleteTransaction(String id) {
    _txRepo.delete(id);
    state = state.copyWith(transactions: _txRepo.getAll());
  }
}
