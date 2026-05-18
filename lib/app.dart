import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/dashboard/providers/dashboard_provider.dart';

class BankakApp extends ConsumerWidget {
  const BankakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Vault',
      locale: Locale(state.isArabic ? 'ar' : 'en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.dark(isArabic: state.isArabic),
      routerConfig: appRouter,
    );
  }
}
