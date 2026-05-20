import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/presentation/home_tab.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';
import '../../settings/presentation/settings_tab.dart';
import '../../settings/providers/settings_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class MainDashboard extends ConsumerStatefulWidget {
  const MainDashboard({super.key});

  @override
  ConsumerState<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends ConsumerState<MainDashboard> {
  int _currentIndex = 0;

  final _tabs = const [
    HomeTab(),
    AnalyticsScreen(),
    TransactionsScreen(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(settingsProvider).state.isArabic;
    final labels = isArabic
        ? ['الرئيسية', 'التحليلات', 'العمليات', 'الإعدادات']
        : ['Home', 'Analytics', 'Transactions', 'Settings'];
    final icons = const [
      Icons.home_outlined,
      Icons.bar_chart_outlined,
      Icons.receipt_long_outlined,
      Icons.settings_outlined,
    ];
    const activeIcons = [
      Icons.home_rounded,
      Icons.bar_chart_rounded,
      Icons.receipt_long_rounded,
      Icons.settings_rounded,
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          indicatorColor: const Color(0xFF4A7CF7).withOpacity(0.2),
          destinations: List.generate(4, (i) {
            return NavigationDestination(
              icon: Icon(icons[i]),
              selectedIcon: Icon(activeIcons[i]),
              label: labels[i],
            );
          }),
        ),
      ),
    );
  }
}
