import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/models/transaction.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/budget_repository.dart';
import 'data/services/native_integration_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/budget/providers/budget_provider.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(BankakTransactionAdapter());
  Hive.registerAdapter(BudgetEntryAdapter());

  final txBox = await Hive.openBox<BankakTransaction>('transactions');
  final budgetBox = await Hive.openBox<BudgetEntry>('budgets');

  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  final txRepo = TransactionRepository(secureStorage);
  await txRepo.init();

  final budgetRepo = BudgetRepository();
  await budgetRepo.init();

  final settingsRepo = SettingsRepository(prefs);
  final authRepo = AuthRepository(secureStorage);

  NativeIntegrationService(
    onSmsReceived: (smsBody) {
      // Will be handled by the Riverpod provider
    },
  );

  runApp(
    ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(txRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        authRepositoryProvider.overrideWithValue(authRepo),
        budgetRepositoryProvider.overrideWithValue(budgetRepo),
      ],
      child: const BankakApp(),
    ),
  );
}
