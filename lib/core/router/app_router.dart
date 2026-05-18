import 'package:go_router/go_router.dart';
import '../../features/setup/presentation/setup_screen.dart';
import '../../features/auth/presentation/lock_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/transactions/presentation/transaction_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/setup',
  routes: [
    GoRoute(
      path: '/setup',
      name: 'setup',
      builder: (context, state) => const SetupScreen(),
    ),
    GoRoute(
      path: '/lock',
      name: 'lock',
      builder: (context, state) => const LockScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainDashboard(),
    ),
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/transactions',
      name: 'transactions',
      builder: (context, state) => const TransactionsScreen(),
    ),
    GoRoute(
      path: '/transaction/:id',
      name: 'transactionDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TransactionDetailScreen(transactionId: id);
      },
    ),
  ],
);
