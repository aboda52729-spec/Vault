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
import 'data/services/native_integration_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(BankakTransactionAdapter());
  await Hive.openBox<BankakTransaction>('transactions');

  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  final txRepo = TransactionRepository(secureStorage);
  await txRepo.init();

  final settingsRepo = SettingsRepository(prefs);
  final authRepo = AuthRepository(secureStorage);

  // Initialize native SMS listener
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
      ],
      child: const BankakApp(),
    ),
  );
}
